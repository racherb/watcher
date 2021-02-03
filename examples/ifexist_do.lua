#!/usr/bin/env tarantool

local fw = require('watcher').file

--Function that processes a file after it arrives
local function process_file(the_file)
    print('Waiting for the file ...')
    if fw.creation(the_file).ans then
        print('Orale! The file ' .. the_file[1] .. ' is ready')
        --Write your code here!
        --...
        --...
    else
        print('Ugh! The file has not arrived')
    end
end

--Processes the '/tmp/filex.txt' file
--process_file({'/tmp/filex.txt'})

local fiber = require('fiber')
fiber.create(process_file, {'/tmp/fileY.txt'})

