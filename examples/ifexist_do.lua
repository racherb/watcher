#!/usr/bin/env tarantool

local filewatcher = require('watcher').file
local waitfor = require('watcher').waitfor

--Function that processes a file after it arrives
local function process_file(the_file)
    print('Waiting for the file ...')
    local res = waitfor(
        filewatcher.creation(the_file).wid
    )
    if res.ans then
        print('Orale! The file ' .. the_file[1] .. ' is ready')
        --Write your code here!
        --...
        --...
    else
        print("'D'OH.! The file has not arrived")
    end
end

process_file({'/tmp/abc.x'})

os.exit()

