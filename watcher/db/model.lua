#!/usr/bin/env tarantool
------------
-- Schema Definition for Watchers
-- ...
-- @module entity watcher
-- @author hernandez, raciel
-- @license MIT
-- @copyright Raciel Hernández 2020

--avro-schema
local schema = {
    awatcher = {
        name = "awatcher",
        type = "record",
        fields = {
            {name="wid", type="long"},
            {name="type", type="string"},
            {name="what", type="string"},
            {name="dini", type="long"},
            {name="dend", type="long"}
        }
    },
    watchables = {
        name = "watchables",
        type = "record",
        fields = {
            {name="wid", type="long"},
            {name="obj", type="string"},
            {name="dre", type="long"},
            {name="ans", type="boolean"},
            {name="msg", type="string"},
            {name="den", type="long"}
        }
    }
}

return {
    schema = schema
}
