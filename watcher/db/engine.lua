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
local fiber = require('fiber')
local log = require('log')

strict.on()

local enty = require('db.entity')
local awa = enty.awatcher()
local wat = enty.watchables()

local FILE = require('types.file').FILE

local function create_spaces()
    if not pcall(box.schema.create_space, 'awatcher') then
        return false
    else
        log.info('The awatcher scheme has been successfully created')
        box.space.awatcher:create_index('awa_pk',
        {
            type = 'hash',
            parts = {1, 'unsigned'}
        }
    )
    end
    if not pcall(box.schema.create_space, 'watchables') then
        return false
    else
        log.info('The watchables scheme has been successfully created')
        box.space.watchables:create_index('wat_uk',
            {
                type = 'tree',
                parts = {{1, 'unsigned'}, {2, 'str'}},
                unique = true
            }
        )
        box.space.watchables:create_index('wat_ak_mssg',
            {
                type = 'tree',
                parts = {{1, 'unsigned'}, {5, 'str'}},
                unique = false
            }
        )
    end
    return true
end

local function start()
    box.cfg{}
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
end

-- Id Generator for awatcher table
local function wig()
    local nid = clock.realtime64()/1e3
    while box.space.awatcher:get(nid) do
        nid = nid + 1
    end
    return nid
end

-- Register a new watcher
local function new(what, kind)
    local id = wig()

    --New active watcher definition
    local nawa = {
        wid = id,
        type = kind,
        what = what,
        dini = clock.realtime64(),
        dend = 0
        }

    local ok, tuple = awa.flatten(nawa)
    print(ok)

    if ok then
        box.space.awatcher:insert(tuple)
        return true, id
    else
        return false, tuple
    end
end

local function get(wid)
    return box.space.awatcher:get(wid)
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
        --FILE.IS_PATTERN
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
            box.space.watchables:insert(tuple)
            return true, object
        else
            return false, tuple
        end
    else
        return false, 'WID_OPEN_IS_REQUIRED'
    end
end

local function put(wid, object)
    local the_watcher = get(wid)
    -- Subscribe if wid exist and not finish yet
    if the_watcher and the_watcher[5]==0 then
        local dreg = clock.realtime64()
        local watchb = {
            wid = wid,
            obj = object,
            dre = dreg,
            ans = true,
            msg = FILE.HAS_BEEN_CREATED,
            den = dreg
        }

        local ok, tuple = wat.flatten(watchb)

        if ok then
            box.space.watchables:insert(tuple)
            return true, object
        else
            return false, tuple
        end
    else
        return false, 'WID_OPEN_IS_REQUIRED'
    end
end

local function del(wid)
    local s = box.space.watchables.index.wat_uk
    local sel = s:select(wid)
    for _,v in pairs(sel) do
        s:delete({wid, v[3]})
    end
    box.space.awatcher:delete(wid)
end

-- Truncate watcher table
local function trun()
    box.space.watchables:truncate()
    box.space.awatcher:truncate()
end

local function upd(wid, object, ans, msg)
    box.space.watchables.index.wat_uk:update(
        {wid, object},
        {
            {'=', 4, ans},
            {'=', 5, msg},
            {'=', 6, clock.realtime64()}
        }
    )
end

local function match(wid)
    return box.space.watchables.index.wat_ak_mssg:count(
        {wid, FILE.HAS_BEEN_CREATED}
    )
end

local function stat(wid)
    return {
        total = box.space.watchables:len(),
        match = box.space.watchables.index.wat_ak_mssg:count(
            {wid, FILE.HAS_BEEN_CREATED}
        )
    }
end

-- Close and end watcher wid
local function endw(wid, dmatch)
    local t_watcher = get(wid)
    if t_watcher then
        local v_end = clock.realtime64()
        box.space.awatcher:update(
            wid, {{'=', 5, v_end}}
        )
    end

    if match(wid) >= dmatch then
        return true
    else
        return false
    end
end

local awatcher = {
    wig = wig,        --Generate a Watcher Id
    new = new,        --Create a new Watcher
    add = add,        --Add watchables to Watcher
    put = put,
    get = get,        --Get the active watcher from wid
    endw = endw,      --Close Watcher and watchables
    upd = upd,        --Update watchables data
    del = del,        --Delete active watchers and watchables by wid
    trun = trun,
    stat = stat,
    match = match
}

return {
    start = start,
    awatcher = awatcher
}