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
            {name="wid", type="long" },
            {name="type", type="string" },
            {name="what", type="string"},
            {name="dini", type="long"},
            {name="dend", type="long*"},
            {
                name = "watchables",
                type = {
                    type = "array",
                    items = {
                        name = "objects",
                        type = "record",
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
}

--local x = {wid=1, type='FILE_DELETION', what='/tmp/tisfile.txt', dini=200425, dend=0, watchables={{fid=109, ans=false, msg='', object='/tmp/thisfile.txt'}}}

return {
    schema = schema
}
