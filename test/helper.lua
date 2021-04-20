#!/usr/bin/env tarantool

package.path = package.path .. '../watcher/src/?.lua;../watcher/?.lua'

local fiber = require('fiber')

--Define Helpers
local helper = {}

local function remove_file(file, waitfor)
    fiber.sleep(waitfor)
    os.remove(file)
end

local function remove_tmp_files(waitfor)
    fiber.sleep(waitfor)
    os.execute('rm -rf /tmp/lua_*')
end

local function remove_tmp_folder(waitfor)
    fiber.sleep(waitfor)
    os.execute('rm -rf /tmp/thefolder')
end

local function create_file(file, waitfor)
    fiber.sleep(waitfor)
    os.execute('touch ' .. file)
end

local function append_file(file, waitfor)
    fiber.sleep(waitfor)
    local command = 'echo "*UYHBVCDCV" >> ' ..file
    os.execute(command)
end

local function create_nfiles(n)
    for _=1, n do
        os.tmpname()
    end
end

helper.remove_file = remove_file
helper.remove_tmp_files = remove_tmp_files
helper.remove_tmp_folder = remove_tmp_folder
helper.create_file = create_file
helper.append_file = append_file
helper.create_nfiles = create_nfiles

return helper