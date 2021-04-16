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

local strict = require('strict')
local fiber = require('fiber')
local errno = require('errno')
local log = require('log')

local db = require('db.engine')
local awatcher = require('db.engine').spaces.awatcher
local ut = require('util')
local fwa = require('file_watcher')

local WATCHER = require('types.file').WATCHER
local OUTPUT = require('types.file').OUTPUT
local EXIT = require('types.file').EXIT
local SORT = require('types.file').SORT
local FILE = require('types.file').FILE

local sck = require('sanity_check') --for sanity check

strict.on()

local message

local function apply_func(atomic_func, wlist)
    for i=1,#wlist do
        atomic_func(wlist[i])
    end
end

--Create Watcher
local function create_watcher(
    --[[required]] wlist,       --Watch List
    --[[required]] wkind,       --Watch Kind
    --[[optional]] afunc        --Function(watch_list)
)

    local cwlist
    if wkind == WATCHER.FILE_CREATION then
        cwlist = ut.deduplicate(wlist)
    else
        cwlist = fwa.consolidate(wlist)
    end

    local wid
    local nwid = db.awatcher.new(
        ut.tostring(wlist),
        wkind
    )
    if nwid.ans then
        wid = nwid.wid
    else
        message = {'Watcher could not be created', '-', errno.strerror()}
        log.error(table.concat(message, ' '))
    end

    if wid then
        if afunc then
            --Apply atomic function afunc to each cwlist item
            local deb_info = debug.getinfo(afunc)
            fiber.create(apply_func, deb_info.func, cwlist)
        end
        return {
            ans = true,
            wid = wid,
            kind = wkind,
            list = cwlist
        }
    else
        return
        {
            ans = false,
            wid = nil,
            kind = wkind,
            list = nil
        }
    end
end

--Run Watcher
local function run_watcher(watcher, parm)
    if watcher.ans then
        if watcher.kind == WATCHER.FILE_DELETION then
            local fib = fiber.create(
                fwa.deletion,
                watcher.wid,  --watcher id
                watcher.list, --watch list consolidate
                parm[1],      --maxwait
                parm[2],      --interval
                parm[3],      --orden
                parm[4],      --cases
                parm[5]       --match
            )
            if fib then
                fib:name(string.format('FWD-%s', tostring(watcher.wid)))
                return {
                    fid = fib:id(),
                    wid = watcher.wid
                }
            end
        elseif watcher.kind == WATCHER.FILE_CREATION then
            local fib = fiber.create(
                fwa.creation,
                watcher.wid,  --watcher id
                watcher.list, --watch list consolidate
                parm[1],      --maxwait
                parm[2],      --interval
                parm[3],      --minsize
                parm[4],      --stability
                parm[5],      --novelty
                parm[6]       --match
            )
            if fib then
                fib:name(string.format('FWC-%s', tostring(watcher.wid)))
                return {
                    fid = fib:id(),
                    wid = watcher.wid
                }
            end
        elseif watcher.kind == WATCHER.FILE_ALTERATION then
            local fib = fiber.create(
                fwa.alteration,
                watcher.wid,  --watcher id
                watcher.list, --watch list consolidate
                parm[1],      --maxwait
                parm[2],      --interval
                parm[3],      --awhat
                parm[4]       --nmatch
            )
            if fib then
                fib:name(string.format('FWA-%s', tostring(watcher.wid)))
                return
                {
                    fid = fib:id(),
                    wid = watcher.wid
                }
            end
        end
    end
    --Fail
    return {
        fid = nil,
        wid = watcher.wid,
        stt = 'failed'
    }
end

--Monitoring watcher
--local function monitoring()

--end

local function file_deletion(
    --[[required]] wlist,
    --[[optional]] maxwait,
    --[[optional]] interval,
    --[[optional]] options
)

    local sck_wlist = sck.wlist(wlist)
    assert(sck_wlist.ans, sck_wlist.msg)

    local _maxwait = maxwait or WATCHER.MAXWAIT
    local sck_maxwait = sck.maxwait(_maxwait)
    assert(sck_maxwait.ans, sck_maxwait.msg)

    local _interval = interval or WATCHER.INTERVAL
    local sck_interval = sck.maxwait(_interval)
    assert(sck_interval.ans, sck_interval.msg)

    --Create watcher
    local watcher = create_watcher(
        wlist,
        WATCHER.FILE_DELETION,
        nil
    )
    --function(x, y) os.execute('cp ' ..x .. ' /tmp/_copy/') end

    local nfiles
    if watcher then
        nfiles = #(watcher.list)
    else
        log.error(string.format('%s - Unable to create the watcher', OUTPUT.WATCHER_WAS_NOT_CREATED))
        os.exit(EXIT.WATCHER_WAS_NOT_CREATED)
    end

    assert(
        nfiles ~= 0,
        OUTPUT.NOTHING_FOR_WATCH
    )

    local _options = options or {sort = SORT.NO_SORT, cases = 0, match = 0}

    local _sort = _options[1] or SORT.NO_SORT
    local _cases = _options[2] or 0
    local _match = _options[3] or 0

    if _cases==0 then _cases = nfiles end
    if _match==0 then _match = nfiles end

    assert(tonumber(_cases), OUTPUT.N_CASES_NOT_VALID)
    assert(tonumber(_match), OUTPUT.N_MATCH_NOT_VALID)

    --Run the watcher for specific params
   return run_watcher(
       watcher,
       {
           _maxwait,
           _interval,
           _sort,
           _cases,
           _match
        }
   )

end

local function file_creation(
    wlist,
    maxwait,
    interval,
    minsize,
    stability,
    novelty,
    nmatch
)
    --Validate th user inputs
    local sck_wlist = sck.wlist(wlist)
    assert(sck_wlist.ans, sck_wlist.msg)

    local _maxwait = maxwait or WATCHER.MAXWAIT
    local sck_maxwait = sck.maxwait(_maxwait)
    assert(sck_maxwait.ans, sck_maxwait.msg)

    local _interval = interval or WATCHER.INTERVAL
    local sck_interval = sck.interval(_interval, _maxwait)
    assert(sck_interval.ans, sck_interval.msg)

    local _minsize = minsize or 0
    local sck_size = sck.size(_minsize)
    assert(sck_size.ans, sck_size.msg)

    if stability then
        local sck_stability = sck.stability(stability)
        assert(sck_stability.ans, sck_stability.msg)
    end

    if novelty then
        local sck_novelty = sck.novelty(novelty)
        assert(sck_novelty.ans, sck_novelty.msg)
    end

    --Create watcher
    local watcher = create_watcher(
        wlist,
        WATCHER.FILE_CREATION,
        nil
    )

    local nfiles
    if watcher then
        nfiles = #(watcher.list)
    else
        log.error(string.format('%s - Unable to create the watcher', OUTPUT.WATCHER_WAS_NOT_CREATED))
        os.exit(EXIT.WATCHER_WAS_NOT_CREATED)
    end

    assert(
        nfiles ~= 0,
        OUTPUT.NOTHING_FOR_WATCH
    )

    local _match = nmatch or nfiles -- match for all cases

    --Run the watcher for specific params
    return run_watcher(
        watcher,
        {
            _maxwait,
            _interval,
            _minsize,
            stability,
            novelty,
            _match
         }
    )
end


local function file_alteration(
    --[[required]] wlist,
    --[[optional]] maxwait,
    --[[optional]] interval,
    --[[optional]] awhat,
    --[[optional]] nmatch
)

    --Validate th user inputs
    local sck_wlist = sck.wlist(wlist)
    assert(sck_wlist.ans, sck_wlist.msg)

    local _maxwait = maxwait or WATCHER.MAXWAIT
    local sck_maxwait = sck.maxwait(_maxwait)
    assert(sck_maxwait.ans, sck_maxwait.msg)

    local _interval = interval or WATCHER.INTERVAL
    local sck_interval = sck.maxwait(_interval)
    assert(sck_interval.ans, sck_interval.msg)

    local _awhat = awhat or FILE.ANY_ALTERATION
    assert(
        tonumber(_awhat) and _awhat <= '8',
        OUTPUT.ALTER_WATCH_NOT_VALID
    )

    local watcher = create_watcher(
        wlist,
        WATCHER.FILE_ALTERATION,
        nil
    )

    local nfiles
    if watcher then
        nfiles = #(watcher.list)
    else
        log.error(string.format('%s - Unable to create the watcher', OUTPUT.WATCHER_WAS_NOT_CREATED))
        os.exit(EXIT.WATCHER_WAS_NOT_CREATED)
    end

    assert(
        nfiles ~= 0,
        OUTPUT.NOTHING_FOR_WATCH
    )

    local _match = nmatch or nfiles

        --Run the watcher for specific params
   return run_watcher(
    watcher,
    {
        _maxwait,
        _interval,
        _awhat,
        _match
     }
    )
end

--Wait for a watcher to finish
local function wait_for_watcher(wid)
    local waiting = true
    --local s = box.space.awatcher
    local watcher

    while (waiting) do
        fiber.sleep(5)
        watcher = awatcher:select(wid)

        if watcher[1][5] ~=0 then
            waiting = false
            --break
        end
    end

    return {
        wid = watcher[1][1],
        ans = watcher[1][6],
        time = (watcher[1][5] - watcher[1][4])/1000000000 --seconds
    }

end

local file = {}
file.deletion = file_deletion
file.creation = file_creation
file.alteration = file_alteration

return {
    create = create_watcher,
    run = run_watcher,
    waitfor = wait_for_watcher,
    file = file
}

--data-watcher
--mem-watcher
--vars-watcher