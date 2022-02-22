#!/usr/bin/env tarantool
------------
-- DB Watcher Engine
-- ...
-- @module watcher engine
-- @author hernandez, raciel
-- @license MIT
-- @copyright Raciel Hernández 2020

local strict = require('strict')
local clock = require('clock')
local box = require('box')
local log = require('log')

strict.on()

local FILE = require('types.file').FILE
local WATCHER = require('types.file').WATCHER

local function create_spaces()

    if not pcall(box.schema.create_space, 'awatcher') then
        return false
    else
        log.info('The awatcher scheme has been successfully created')
        box.space.awatcher:create_index('awa_pk',
        {
            type = 'hash',
            unique = true,
            parts = {1, 'unsigned'}
        })
        box.space.awatcher:create_index('awa_name',
        {
            type = 'tree',
            unique = false,
            parts = {{8, 'str'}, {9, 'str'}}
        })
    end

    log.info('The awatcher scheme index has been successfully created')

    if not pcall(box.schema.create_space, 'watchables') then
        return false
    else
        log.info('The watchables scheme has been successfully created')

        box.space.watchables:create_index(
            'wat_uk',
            {
                type = 'tree',
                parts = {{1, 'unsigned'}, {2, 'str'}},
                unique = true
            }
        )
        log.info('Index wat_uk has been successfully created')

        box.space.watchables:create_index('wat_ak_mssg',
            {
                type = 'tree',
                parts = {{1, 'unsigned'}, {5, 'str'}},
                unique = false
            }
        )
        log.info('Index wat_ak_mssg has been successfully created')

        box.space.watchables:create_index('wat_ak_answ',
            {
                type = 'tree',
                parts = {{1, 'unsigned'}, {4, 'boolean'}},
                unique = false
            }
        )
        log.info('Index wat_ak_answ has been successfully created')
    end

    return true

end

local function start()

    box.cfg{
        listen = 3301, --listen = os.getenv("LISTEN_URI"),
        log_level = 5,
        log = 'watcher.log',
        background = false,
        pid_file = 'watcher.pid',
        --work_dir = '/tmp/',
        checkpoint_interval = 60,
        force_recovery = true
    }

    box.once('init', function()
        local ok = create_spaces()
        if not ok then
            box.space._schema:delete('onceinit')
            log.error('The base schemes for watcher could not be generated')
        end
    end)

    --User spaces initialization
    local plugin = require('plugins.default')

    box.once('init_default', function()
        local ok = plugin.user_spaces_def()
        if not ok then
            box.space._schema:delete('onceinit_default')
            log.error('The plugin schemes could not be generated')
        end
    end)

    local enty = require('db.entity')
    local awa = enty.awatcher()
    local wat = enty.watchables()

    return awa, wat

end

local awa, wat = start()

local box_space_awatcher = box.space.awatcher
local box_space_watchables = box.space.watchables

-- Id Generator for awatcher table
local function wig()
    local nid = clock.realtime64()/1e3
    while box_space_awatcher:get(nid) do
        nid = nid + 1
    end
    return nid
end

--Active Watcher List
local function list(wid)
    if not wid then
        return box_space_awatcher:select()
    else
        return box_space_watchables:select({wid})
    end
end

-- Register a new watcher
local function new(
    what,
    kind
)
    local id = wig()

    --New active watcher definition
    local nawa = {
        wid = id,
        type = kind,
        what = what,
        dini = clock.realtime64(),  --wall time in nanosecs
        dend = 0,
        answ = '',
        fid = 0,
        repo = '',
        tag = ''
    }

    local ok, tuple = awa.flatten(nawa)

    if ok then
        box_space_awatcher:insert(tuple)
        return {
            ans = true,
            wid = id
        }
    else
        --TODO: Este valor 'tuple' devuelve el error en caso de ocurrir
        --print(tuple)
        return {
            ans = false,
            wid = nil
        }
    end
end

--Set the fiber id when watcher is running
local function set_fid(wid, fid)
    box_space_awatcher:update(wid, {{'=', 7, fid}})
end

--Get wid by given name
local function wid_by_name(name, tag)
    local s = box_space_awatcher.index.awa_name
    local watcher = s:select({name, tag})
    if watcher[1] then
        return watcher[1][1]
    else
        return nil
    end
end

local function get(wid)
    return box_space_awatcher:get(wid)
end

local function set_name(wid, name, tag)
    local _name = name or ''
    local _tag = tag or ''
    local _wid = wid_by_name(_name, _tag)
    local _widx = get(wid)
    if not _widx then
        print('No existe un watcher con el identificador dado')
    elseif (_wid and _wid==wid) or not _wid then
        box_space_awatcher:update(
            wid,
            {
                {'=', 8, _name},
                {'=', 9, _tag}
            }
        )
    else
        --TODO: Normalizar salida
        print('Ya existe un repoitorio con ese nombre')
    end
end

--Add watchables
local function add(
    wid,
    object,
    answer,
    message
)
    local the_watcher = get(wid)

    -- Subscribe if wid exist and not finish yet
    if the_watcher and the_watcher[5]==0 then
        local _answer = answer or false
        local _message = message or FILE.NOT_YET_CREATED --'FILE_NOT_CREATED_YET'

        local watchb = {
            wid = wid,
            obj = object,
            dre = clock.realtime64(),
            ans = _answer,
            msg = _message,
            den = 0
        }

        local ok, tuple = wat.flatten(watchb)

        if ok then
            box_space_watchables:insert(tuple)
            return true, object
        else
            return false, tuple
        end
    else
        return false, 'WID_OPEN_IS_REQUIRED'
    end
end

local function put(
    wid,
    object,
    ans,
    msg
)
    local the_watcher = get(wid)

    -- Subscribe if wid exist and not finish yet
    if the_watcher and the_watcher[5]==0 then
        local dreg = clock.realtime64()
        local watchb = {
            wid = wid,
            obj = object,
            dre = dreg,
            ans = ans,
            msg = msg,
            den = dreg
        }

        local ok, tuple = wat.flatten(watchb)

        if ok then
            box_space_watchables:insert(tuple)
            return true, object
        else
            return false, tuple
        end
    else
        return false, 'WID_OPEN_IS_REQUIRED'
    end
end

local function del(
    wid
)

    local s = box_space_watchables.index.wat_uk
    local sel = s:select(wid)

    for _,v in pairs(sel) do
        s:delete({wid, v[2]})
    end

    return box_space_awatcher:delete(wid)

end

-- Truncate watcher table
local function trun()
    box_space_watchables:truncate()
    box_space_awatcher:truncate()
end

local function upd(
    wid,
    object,
    ans,
    msg
)
    box_space_watchables.index.wat_uk:update(
        {
            wid,
            object
        },
        {
            {'=', 4, ans},
            {'=', 5, msg},
            {'=', 6, clock.realtime64()}
        }
    )
end

local function match(
    wid,
    wtype
)
    local _wtype = wtype or 'FWC' --WATCHER.FILE_CREATION is Default
    local s = box_space_watchables.index.wat_ak_mssg

    if _wtype == WATCHER.FILE_CREATION then
        return s:count(
            {
                wid,
                'C' --FILE.HAS_BEEN_CREATED
            }
        )
    elseif _wtype == WATCHER.FILE_DELETION then
        return s:count(
            {
                wid,
                'X' --FILE.DELETED
            }
        )
    else
        return s:count(
            {
                wid,
                wtype
            }
        )
    end
end

local function stat(
    wid
)

    local sel = box.space.watchables.index.wat_ak_mssg

    return {
        total = box_space_watchables:len(),
        match = sel:count(
            {
                wid,
                FILE.HAS_BEEN_CREATED
            }
        )
    }
end

-- Close and end watcher wid
local function close(
    wid,
    dmatch,
    kind
)

    local watcher = get(wid)
    local _kind = kind or watcher.kind
    local _dmatch = dmatch or box_space_watchables:count({wid})

    local result

    if _dmatch~=0 and match(wid, _kind) >= _dmatch then
        result = true
    else
        result = false
    end

    if watcher then
        local v_end = clock.realtime64()
        box_space_awatcher:update(
            wid,
            {
                {'=', 5, v_end},
                {'=', 6, result}
            }
        )
    end

    return result

end

local awatcher = {
    wig = wig,        --Generate a Watcher Id
    new = new,        --Create a new Watcher
    set = set_fid,    --Set fiber id
    add = add,        --Add watchables to Watcher
    put = put,
    get = get,        --Get the active watcher from wid
    close = close,    --Close Watcher and watchables
    upd = upd,        --Update watchables data
    del = del,        --Delete active watchers and watchables by wid
    trun = trun,
    stat = stat,
    match = match,
    list = list,
    name = set_name,
    widbn = wid_by_name
}

local spaces = {
    awatcher = box_space_awatcher,
    watchables = box_space_watchables
}

start()

return {
    start = start,
    awatcher = awatcher,
    spaces = spaces
}