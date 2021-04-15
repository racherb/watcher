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
--local errno = require('errno')
local log = require('log')

local db = require('db.engine')
local awatcher = require('db.engine').spaces.awatcher
local ut = require('util')
local fwa = require('file_watcher')

local WATCHER = require('types.file').WATCHER
local OUTPUT = require('types.file').OUTPUT
local SORT = require('types.file').SORT
local FILE = require('types.file').FILE

strict.on()

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

    local _, wid = db.awatcher.new(
        ut.tostring(cwlist),
        wkind
    )

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
                fib:name('FWD-'..tostring(watcher.wid))
                return {
                    fid = fib:id(),
                    wid = watcher.wid,
                    stt = 'running'
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
                fib:name('FWD-'..tostring(watcher.wid))
                return {
                    fid = fib:id(),
                    wid = watcher.wid,
                    stt = 'running'
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
                fib:name('FWD-'..tostring(watcher.wid))
                return
                {
                    fid = fib:id(),
                    wid = watcher.wid,
                    stt = 'running'
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

    assert(
        wlist and (type(wlist)=='table') and (#wlist~=0),
        OUTPUT.WATCH_LIST_NOT_VALID
    )

    local _maxwait = maxwait or WATCHER.MAXWAIT
    assert(
        type(_maxwait)=='number' and _maxwait > 0,
        OUTPUT.MAXWAIT_NOT_VALID
    )

    local _interval = interval or WATCHER.INTERVAL
    assert(
        type(_interval)=='number' and _interval > 0,
        OUTPUT.INTERVAL_NOT_VALID
    )

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
        --TODO: Normalize this
        log.error('Cannot create the watcher')
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

    assert(
        wlist and (type(wlist)=='table') and (#wlist~=0),
        OUTPUT.WATCH_LIST_NOT_VALID
    )

    local _maxwait = maxwait or WATCHER.MAXWAIT
    assert(
        type(_maxwait)=='number' and _maxwait > 0,
        OUTPUT.MAXWAIT_NOT_VALID
    )

    local _interval = interval or WATCHER.INTERVAL
    assert(
        type(_interval)=='number' and _interval > 0,
        OUTPUT.INTERVAL_NOT_VALID
    )

    local _minsize = minsize or 0
    assert(
        _minsize and type(_minsize)=='number' and _minsize >= 0,
        OUTPUT.MINSIZE_NOT_VALID
    )

    if stability then
        assert(
            stability and type(stability)=='table' and #stability~=0,
            OUTPUT.STABILITY_NOT_VALID
        )
        assert(
            stability[1] and type(stability[1])=='number' and stability[1]>0,
            OUTPUT.CHECK_SIZE_INTERVAL_NOT_VALID
        )
        assert(
            stability[2] and type(stability[2])=='number' and stability[2]>0,
            OUTPUT.ITERATIONS_NOT_VALID
        )
    end

    if novelty then
        assert(
            type(novelty)=='table' and #novelty~=0,
            OUTPUT.NOVELTY_NOT_VALID
        )
        assert(
            novelty[1] and type(novelty[1])=='number',
            OUTPUT.DATE_FROM_NOT_VALID
        )
        assert(
            novelty[2] and type(novelty[2])=='number',
            OUTPUT.DATE_UNTIL_NOT_VALID
        )
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
        --TODO: Normalize this
        log.error('Cannot create the watcher')
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

    assert(
        wlist and (type(wlist)=='table') and (#wlist~=0),
        OUTPUT.WATCH_LIST_NOT_VALID
    )

    local _maxwait = maxwait or WATCHER.MAXWAIT
    assert(
        type(_maxwait)=='number' and _maxwait > 0,
        OUTPUT.MAXWAIT_NOT_VALID
    )

    local _interval = interval or WATCHER.INTERVAL
    assert(
        type(_interval)=='number' and _interval > 0,
        OUTPUT.INTERVAL_NOT_VALID
    )

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
        --TODO: Normalize this
        log.error('Cannot create the watcher')
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