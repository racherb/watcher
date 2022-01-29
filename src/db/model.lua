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
            {name="wid",  type="long"},     --1. Watcher ID
            {name="type", type="string"},   --2. Watcher TYPE/KIND
            {name="what", type="string"},   --3. What is watching
            {name="dini", type="long"},     --4. Begin datetimete
            {name="dend", type="long"},     --5. End for watcher
            {name="answ", type="string"},   --6. Answer or end status
            {name="fid",  type="long"},     --7. Fiber Id
            {name="repo", type="string"},   --8. Repository name
            {name="tag",  type="string"}    --9. Tag name
        }
    },
    watchables = {
        name = "watchables",
        type = "record",
        fields = {
            {name="wid", type="long"},      --1. Watcher ID
            {name="obj", type="string"},    --2. Objet name
            {name="dre", type="long"},      --3. Date register
            {name="ans", type="boolean"},   --4. Answer
            {name="msg", type="string"},    --5. Message
            {name="den", type="long"}       --6. Date end
        }
    }
}

return {
    schema = schema
}
