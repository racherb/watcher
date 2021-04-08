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

package.path = package.path .. ';src/?.lua'

local file_watcher = require("file_watcher")

return {
    file = file_watcher
}

--file-watcher
--data-watcher
--mem-watcher
--vars-watcher