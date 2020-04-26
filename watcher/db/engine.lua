#!/usr/bin/env tarantool
------------
-- DB Watcher Engine
-- ...
-- @module watcher engine
-- @author hernandez, raciel
-- @license MIT
-- @copyright Raciel Hernández 2020

local strict = require("strict")
strict.on()

local awatcher = require("db.entity").awatcher()

local function start()
    box.cfg{}
    box.once('init', function()
        box.schema.create_space('awatcher')
        box.space.awatcher:create_index(
            "primary", {type = 'hash', parts = {1, 'unsigned'}}
        )
        box.space.awatcher:create_index(
            "status", {type = "tree", parts = {2, 'str'}}
        )
    end)
end

-- Register a watcher
local function subscribe()
    print('ŕegister')
end

local function unsubscribe()
    print('ŕegister')
end

-- Truncate watcher table
local function clear()

end

-- Insert object for watcher
local function insert()

end

local function update()

end

-- Archive data
local function archive()

end

return {
    start = start,
    subscribe = subscribe,
    unsubscribe = unsubscribe,
    insert = insert,
    update = update
}