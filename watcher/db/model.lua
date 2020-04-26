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
        default = {dend=0},
        fields = {
            {name="wid", type="int" },
            {name="type", type="string" },
            {name="what", type="string"},
            {name="dini", type="int"},
            {name="dend", type="int*"},
            {
                name = "watchables",
                type = {
                    type = "record*",
                    name = "objects",
                    default = {ans=false, msg=''},
                    fields = {
                        {name="fid", type="int"},
                        {name="ans", type="boolean*"},
                        {name="msg", type="string*"},
                        {name="object", type="string"}
                    }
                }
            }
        }
    }
}

return {
    schema = schema
}
