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

local avro_compile = avro.compile
local avro_create = avro.create

strict.on()

local function compile_awatcher()
    local s_ok, s_awatcher = avro_create(
        schema.awatcher
    )
    if s_ok then
        local c_ok, c_awatcher = avro_compile(s_awatcher)
        if c_ok then
            log.info('Schema compilation is ok for active watcher')
            return c_awatcher
        else
            log.error('Schema compilation failed for active watcher')
        end
    else
        log.error('Schema creation failed for active watcher')
    end
end

local function compile_watchables()
    local s_ok, s_watchables = avro_create(
        schema.watchables
    )
    if s_ok then
        local c_ok, c_watchables = avro_compile(
            s_watchables
        )
        if c_ok then
            log.info('Schema compilation is ok for watchables')
            return c_watchables
        else
            log.error('Schema compilation failed for watchables')
        end
    else
        log.error('Schema creation failed for watchables')
    end
end

return {
    awatcher = compile_awatcher,
    watchables = compile_watchables
}