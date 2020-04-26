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
            {name="wid", type="int" },
            {name="type", type="string" },
            {name="what", type="string"},
            {name="dini", type="number"},
            {name="dend", type="number*"},
            {
                name = "object",
                type = {
                    type = "record*",
                    name = "object_schema",
                    fields = {
                        {name="fid", type="number"},
                        {name="answ", type="boolean"},
                        {name="mssg", type="string"},
                        {name="value", type="string"}
                    }
                }
            }
        }
    }
}

return {
    schema = schema
}
