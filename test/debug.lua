#!/usr/bin/env tarantool
package.path = package.path .. ';/home/rhernandez/lucy/prj/dev/watcher/src/?.lua'

local core = require('watcher').core
local moni = require('watcher').monit
local fwa = require('watcher').file
local file = require('file_watcher')
local fiber = require('fiber')

--local ans = fwa.deletion({'/tmp/A1'})
--core.sleep(60)
--local inf = moni.info(ans.wid)

--local util = require('watcher').util
--local clist = util.consolidate({'a', 'b'}, {'b'})
--print(#clist)


local MAXWAIT = 60
--local nw = core.create({'/tmp/A*'}, 'FWC')
local wat = fwa.creation({'/tmp/B*','/tmp/A*'}, 3600, 1, nil, nil, nil, 120)
--[[maxwait,
interval,
minsize,
stability,
novelty,
nmatch
]]

core.waitfor(wat.wid)
local res = moni.info(wat.wid)
local prop = (res.ans) and (res.match == 3) and (res.nomatch == 1)

--os.exit(0)
local nw = core.create({'/tmp/AAAA'}, 'FWD')
local rw = file.alteration(nw.wid, {'/tmp/AAAA'}, 10, 1, '1', 1)


--[[
local nw = core.create({'/tmp/A*'}, 'FWC')
local rw = core.run(
    nw.wid,
    {
        maxwait = 60,
        interval = 1,
        minsize = 0,
        stability = nil,
        novelty = nil,
        match = 10
    },
    {
        nil
    }
)

core.waitfor(rw.wid)
local x = moni.info(rw.wid)
print(x.ans)

--]]

print 'end'
os.exit(0)
