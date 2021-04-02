#!/usr/bin/env tarantool
------------
-- Backup Plugins
-- ...
-- @module Backup
-- @author Raciel Hernandez
-- @license MIT
-- @copyright 2021

--local fw = require('watcher').file

-- Genera un backup de los archivos del watcher
local function backup()
    return true
end

--
local function restore()
    return true
end

return {
    backup = backup,
    restore = restore
}