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
local entty = require('db.entity').awatcher()

strict.on()

local entty = require("db.entity").awatcher()

local function start()
    box.cfg{}
    box.once('init', function()
        box.schema.create_space('awatcher')
        box.space.awatcher:create_index(
            "pk", {type = 'hash', parts = {1, 'unsigned'}}
        )
        box.space.awatcher:create_index(
            "ak_what", {type = "tree", parts = {3, 'str'}, unique = false}
        )
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
local function new(what, kind, watchables)
    local p_what = what or assert(false, "WHAT_PARAM_IS_REQUIRED")
    local p_kind = kind
    local p_watchables = watchables

    local id = wid()

    local n_watcher = {
        wid = id,
        type = p_kind,
        what = p_what,
        dini = clock.realtime64(),
        dend = 0,
        watchables = p_watchables
    }
    local is_ok, n_watcher_avro = entty.flatten(n_watcher)
    if is_ok then
        box.space.awatcher:insert(n_watcher_avro)
        return true, id
    else
        return false, n_watcher_avro
    end
end

local function get(wid)
    return box.space.awatcher:get(wid)
end

local function delete(wid)
    return box.space.awatcher:delete(wid)
end

-- Truncate watcher table
local function truncate()
    box.space.awatcher:truncate()
end

local function update(wid, fid, object, ans, msg)

end

local awatcher = {
    wid = wid,
    new = new,
    get = get,
    delete = delete,
    update = update,
    truncate = truncate
}

return {
    start = start,
    awatcher = awatcher
}

--db = require('db.engine')
--db.start()
--db.awatcher.new('/tmp/*', 'FD', {{fid=1, ans=false, msg='', object='/tmp/file_1.txt'}})
