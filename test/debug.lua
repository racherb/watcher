package.path = package.path .. ';/home/rhernandez/lucy/prj/dev/watcher/src/?.lua'

--local core = require('watcher').core
--local moni = require('watcher').monit
local util = require('watcher').util

local clist = util.consolidate({'a', 'b'}, {'b'})
print(#clist)

os.exit(0)

local nw = core.create({'/rmp/*'}, 'FWD')
local rw = core.run(nw.wid, {60, 1, nil, nil, nil, nil})

core.sleep(60)
moni.info(rw.wid)

print 'end'
