#!/usr/bin/env tarantool
------------
-- DB Watcher Entities
-- ...
-- @module entity watcher
-- @author hernandez, raciel
-- @license MIT
-- @copyright Raciel Hernández 2020

local log = require("log")
local avro = require("avro_schema")
local strict = require("strict")

local schema = require("db.model").schema

strict.on()

local function mk_awatcher()
    local s_ok, s_awatcher = avro.create(schema.awatcher)
    if s_ok then
        local c_ok, c_awatcher = avro.compile(s_awatcher)
        if c_ok then
            return c_awatcher
        else
            log.error('Schema compilation failed for aWatcher')
        end
    else
        log.error('Schema creation failed for aWatcher')
    end
end

local function mk_watchables()
    local s_ok, s_watchables = avro.create(schema.watchables)
    if s_ok then
        local c_ok, c_watchables = avro.compile(s_watchables)
        if c_ok then
            return c_watchables
        else
            log.error('Schema compilation failed for Watchables')
        end
    else
        log.error('Schema creation failed for Watchables')
    end
end

return {
    awatcher = mk_awatcher,
    watchables = mk_watchables
}