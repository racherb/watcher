#!/usr/bin/env tarantool
------------
-- DB Watcher Engine
-- ...
-- @module watcher engine
-- @author hernandez, raciel
-- @license MIT
-- @copyright Raciel Hernández 2020

local strict = require("strict")
local clock = require("clock")
local fiber = require("fiber")

strict.on()

local enty = require("db.entity")
local awa = enty.awatcher()
local wat = enty.watchables()

local function create_spaces()
    if not pcall(box.schema.create_space, 'awatcher') then
        return false
    else
        box.space.awatcher:create_index("awa_pk",
        {
            type = 'hash',
            parts = {1, 'unsigned'}
        }
    )
    end
    if not pcall(box.schema.create_space, 'watchables') then
        return false
    else
        box.space.watchables:create_index("wat_uk",
            {
                type = 'tree',
                parts = {{1, 'unsigned'}, {2, 'str'}},
                unique = true
            }
        )
    end
    return true
end

local function start()
    box.cfg{}
    box.once('init', function()
        local ok = create_spaces()
        if not ok then box.space._schema:delete('onceinit') end
    end)

    --User spaces initialization
    local plugin = require('plugins.default')
    box.once('init_default', function()
        local ok = plugin.user_spaces_def()
        if not ok then box.space._schema:delete('onceinit_default') end
    end)
end

-- Id Generator for awatcher table
local function wid()
    local nid = clock.realtime64()/1e3
    while box.space.awatcher:get(nid) do
        nid = nid + 1
    end
    return nid
end

-- Register a new watcher
local function new(what, kind)
    local p_what = what or assert(false, "WHAT_PARAM_IS_REQUIRED")
    local p_kind = kind

    local id = wid()

    --New active watcher definition
    local nawa = {
        wid = id,
        type = p_kind,
        what = p_what,
        dini = clock.realtime64(),
        dend = 0
        }

    local ok, tuple = awa.flatten(nawa)

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
local function add(wid, fid, object)
    local the_watcher = get(wid)
    -- Subscribe if wid exist and not finish yet
    if the_watcher and the_watcher[5]==0 then
        local watchb = {
            wid = wid,
            obj = object,
            fid = fid,
            ans = false,
            msg = 'FW_ACTIVE'
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

local function close(wid)
    local t_watcher = get(wid)
    if t_watcher then
        --Kill all fibers opened by watchables
        local sel = box.space.watchables.index.wat_uk:select(wid)
        for _,v in pairs(sel) do
            if v[2] then pcall(fiber.kill, v[2]) end
        end
        local v_end = clock.realtime64()
        box.space.awatcher:update(
            wid, {{'=', 5, v_end}}
        )
    end
end

local function delete(wid)
    local s = box.space.watchables.index.wat_uk
    local sel = s:select(wid)
    for _,v in pairs(sel) do
        s:delete({wid, v[3]})
    end
    box.space.awatcher:delete(wid)
end

-- Truncate watcher table
local function truncate()
    box.space.watchables:truncate()
    box.space.awatcher:truncate()
end

local function update(wid, object, ans, msg)
    box.space.watchables.index.wat_uk:update(
        {wid, object},
        {
            {'=', 4, ans},
            {'=', 5, msg}
        }
    )
end

local awatcher = {
    wid = wid,        --Generate a Watcher Id
    new = new,        --Create a new Watcher
    add = add,        --Add watchables to Watcher
    get = get,        --Get the active watcher from wid
    close = close,    --Close Watcher and watchables
    update = update,  --Update watchables data
    delete = delete,  --Delete active watchers and watchables by wid
    truncate = truncate
}

return {
    start = start,
    awatcher = awatcher
}

--db = require('db.engine')
--db.start()
--db.awatcher.create('/tmp/*', 'FD')
