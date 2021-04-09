#!/usr/bin/env tarantool

--[[File Watcher Deletion Example
    Match first N items ordered by change date asc
]]

local file_watcher=require('watcher').file
local fiber=require('fiber')

local function remove_file(file, waitfor)
    fiber.sleep(waitfor)
    os.remove(file)
end

os.execute('touch /tmp/f_G.txt')
os.execute('touch /tmp/f_H.txt')
os.execute('touch /tmp/f_I.txt')
os.execute('touch /tmp/f_J.txt')
os.execute('touch /tmp/f_K.txt')
os.execute('touch /tmp/f_L.txt')

local n_match = 2

fiber.create(remove_file, '/tmp/f_G.txt', 2)
fiber.create(remove_file, '/tmp/f_L.txt', 2)
fiber.create(remove_file, '/tmp/f_K.txt', 2)

local ini = os.time()

local SORT_BY = {
    NO_SORT = 'NS',
    ALPHA_ASC = 'AA',
    ALPHA_DSC = 'AD',
    MTIME_ASC = 'MA',
    MTIME_DSC = 'MD'
}

local sort_by = SORT_BY.MTIME_ASC

--This fail for ORT_BY.MTIME_ASC and ORT_BY.MTIME_DSC
res = file_watcher.deletion({'/tmp/f_*'}, 5, 0.5, {'MA', 3, 2})

print('Elapsed time: ' .. os.difftime(os.time() - ini) .. 's')

print(res.wid)
print(res.ans)

os.exit()
