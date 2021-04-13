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
            {name="wid", type="long"},      --Watcher ID
            {name="type", type="string"},   --Watcher TYPE
            {name="what", type="string"},   --What is watching
            {name="dini", type="long"},     --Begin datetimete
            {name="dend", type="long"},     --End for watcher
            {name="answ", type="string"}    --Answer or end status
        }
    },
    watchables = {
        name = "watchables",
        type = "record",
        fields = {
            {name="wid", type="long"},      --Watcher ID
            {name="obj", type="string"},    --Objet name
            {name="dre", type="long"},      --Date register
            {name="ans", type="boolean"},   --Answer
            {name="msg", type="string"},    --Message
            {name="den", type="long"}       --Date end
        }
    }
}

return {
    schema = schema
}
