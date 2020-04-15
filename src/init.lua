#!/usr/bin/env tarantool
------------
-- File Watcher Init
-- Watcher for files, directories, objects and services.
--
-- @module watcher
-- @author hernandez, raciel
-- @license MIT
-- @copyright Raciel Hernández 2019
--

local avro = require("avro_schema")

local function start()
    box.cfg{}

    box.once('init', function()
        --awatchers for Active Watchers
        box.schema.create_space('awatchers')
        box.space.awatchers:create_index(
            "primary", {type = 'hash', parts = {1, 'unsigned'}}
        )
        box.space.awatchers:create_index(
            "status", {type = "tree", parts = {2, 'str'}}
        )
    end)

    local sch_ok, awatchers = avro.create(schema.awatchers)

    if sch_ok then
        -- compile models
        local c_ok, c_awatcher = avro.compile(awatchers)
        if c_ok then
            awatcher_mod = c_awatcher
            return true
        else
            log.error('Schema compilation failed')
        end
    else
        log.info('Schema creation failed')
    end

    return false
end

start()

return {
    start = start
}

--file-watcher
--data-watcher
--mem-watcher
--vars-watcher