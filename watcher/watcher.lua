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

local fw = require("file_watcher")

local file = {
    deletion = fw.deletion,
    creation = fw.creation,
    alteration = fw.alteration
}

return {
    file = file
}

--file-watcher
--data-watcher
--mem-watcher
--vars-watcher