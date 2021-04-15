#!/usr/bin/env tarantool

package.path = package.path .. '../watcher/src/?.lua;../watcher/?.lua'

local fiber = require('fiber')

--Define Helpers
local helper = {}

function helper.remove_file(file, waitfor)
    fiber.sleep(waitfor)
    os.remove(file)
end

function helper.remove_tmp_files(waitfor)
    fiber.sleep(waitfor)
    os.execute('rm -rf /tmp/lua_*')
end

function helper.remove_tmp_folder(waitfor)
    fiber.sleep(waitfor)
    os.execute('rm -rf /tmp/thefolder')
end

function helper.create_file(file, waitfor)
    fiber.sleep(waitfor)
    os.execute('touch ' .. file)
end

function helper.append_file(file, waitfor)
    fiber.sleep(waitfor)
    local command = 'echo "*UYHBVCDCV" >> ' ..file
    os.execute(command)
end

function helper.create_nfiles(n)
    for _=1, n do
        os.tmpname()
    end
end

return helper