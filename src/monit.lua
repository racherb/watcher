#!/usr/bin/env tarantool

local box = require('box')
local spc = require('db.engine').spaces
local awa = spc.awatcher
local wat = box.space.watchables.index.wat_ak_answ

local status
local answer

local function info(wid)
    local watcher = awa:select(wid)
    if watcher and watcher[1] then
        if watcher[1][5]~=0 then
            status = 'completed'
            answer = watcher[1][6]
        else
            status = 'started'
            answer = 'waiting'
        end
        return {
            wid = watcher[1][1],
            type = watcher[1][2],
            what = watcher[1][3],
            status = status,
            ans = answer,
            match = wat:count({wid, true}),
            nomatch = wat:count({wid, false})
        }
    else
        return {
            wid = wid,
            err = 'error'
        }
    end
end

local function match(wid)
    local mwa = wat:select({wid, true})
    return mwa
end

local function nomatch(wid)
    local nwa = wat:select({wid, false})
    return nwa
end

local monitor = {}
monitor.info = info
monitor.match = match
monitor.nomatch = nomatch

return monitor