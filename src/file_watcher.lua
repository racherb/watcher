#!/usr/bin/env tarantool
------------
-- File Watcher.
-- Watcher for files, directories, objects and services.
-- ...
-- @module watcher
-- @author hernandez, raciel
-- @license MIT
-- @copyright Raciel Hernández 2019
------------

local strict = require('strict')
local fiber = require('fiber')
local fio = require('fio')
local dig = require('digest')
local errno = require('errno')
local log = require('log')

local os_time = os.time
local string_find = string.find
local fib_sleep = fiber.sleep
local fio_glob = fio.glob

local db = require('db.engine')
local ut = require('util')

local FILE = require('types.file').FILE
local WATCHER = require('types.file').WATCHER
local OUTPUT = require('types.file').OUTPUT

db.start()

strict.on()

--[[
local FW_DEFAULT = {
    PREFIX = 'FW',
    ACTION = 'CREATION',
    MAXWAIT = 60,
    INTERVAL = 0.5,
    CHECK_INTERVAL = 0.5,
    ITERATIONS = 10
}
]]

local SORT_BY = {
    NO_SORT = 'NS',
    ALPHA_ASC = 'AA',
    ALPHA_DSC = 'AD',
    MTIME_ASC = 'MA',
    MTIME_DSC = 'MD'
}

local BULK_CAPACITY = 1000000

-- Add the last date of file modification
local function add_lst_modif( tbl )
    local t = {}
    local fio_lstat = fio.lstat
    for _, v in pairs( tbl ) do
        local lst_mod = fio_lstat(v)
        if lst_mod then
            t[#t+1] = {v, lst_mod.mtime}
        else
            t[#t+1] = {v, 0} --Artitrary zero for mtime when file not exist
        end
    end
    return t
end

-- Take n items from a table
local function take_n_items(
    --[[required]] tbl,
    --[[required]] nitems )

    if nitems == 0 then
        return tbl --Take all items
    elseif nitems == 1 then
        return { tbl[1] } --Take the first
    else
        --Take the n first items
        local t = {}
        local item
        for i = 1, nitems, 1 do
            if type(tbl[i])=='table' then
                item = tbl[i][1]
            else
                item = tbl[i]
            end
            t[#t+1] = item
        end
        return t
    end
end

--- Sort Files by name or date of modification
-- Sort a list of files by name or change date
-- @param flst table        : File list
-- @param sort_by string    : Sorting criterion
-- @param take_n int        : Return the first N elements for monitoring
-- @return sorted_list table: Sorted list
-- @fixme: Sort for date modification don't work
local function sort_files_by(
    --[[required]] flst,
    --[[optional]] sort_by,
    --[[optional]] take_n)

    if take_n == 0 then return {} end
    if take_n > #flst or not take_n then take_n = #flst end

    if sort_by == SORT_BY.NO_SORT then
        return take_n_items(flst, take_n)
    elseif sort_by == SORT_BY.ALPHA_ASC then
        table.sort(
            flst,
            function(a, b)
                return a < b
            end
        )
        return take_n_items(flst, take_n)

    elseif sort_by == SORT_BY.ALPHA_DSC then
        table.sort(
            flst,
            function(a, b)
                return a > b
            end
        )
        return take_n_items(flst, take_n)

    elseif sort_by == SORT_BY.MTIME_ASC then
        local flst_ex = add_lst_modif(flst)
        table.sort(
            flst_ex,
            function(a, b)
                return a[2] < b[2]
            end
        )

        return take_n_items(flst_ex, take_n)

    elseif sort_by == SORT_BY.MTIME_DSC then
        local flst_ex = add_lst_modif(flst)
        table.sort(
            flst_ex,
            function(a, b)
                return a[2] > b[2]
            end
        )
        return take_n_items(flst_ex, take_n)
    end
end

local bfd_end = fiber.cond() --Bulk file deletion end

--- Watcher for Bulk File Deletion
local function bulk_file_deletion(
    wid,
    bulk,
    maxwait,
    interval,
    nmatch
)
    fib_sleep(0.1)
    local fio_exists = fio.path.lexists
    local ini = os_time()
    local notdelyet = bulk
    while (os_time() - ini) < maxwait do
        for i=1,#notdelyet do
            local file = notdelyet[i]
            if not file then break end
            if not fio_exists(file) then
                db.awatcher.upd(
                    wid, file, true, FILE.DELETED
                )
                notdelyet[i] = nil
            end
        end
        if db.awatcher.match(wid, WATCHER.FILE_DELETION)>=nmatch then
            break
        end
        fib_sleep(interval)
    end
    bfd_end:signal()
end

local bfa_end = fiber.cond() --Bulk file alteration end

--- Watcher for Bulk File Alteration
local function bulk_file_alteration(
    wid,
    bulk,
    awhat,
    maxwait,
    interval,
    nmatch
)
    fib_sleep(0.1)

    local fio_exists = fio.path.lexists
    local fio_lstat = fio.lstat
    local dig_sha256 = dig.sha256

    local io_open = io.open
    local fio_is_dir = fio.path.is_dir
    local fio_listdir = fio.listdir

    local ini = os_time()
    local not_alter_yet = bulk
    local is_over = false
    while (os_time() - ini) < maxwait do
        for i=1,#not_alter_yet do
            if not_alter_yet[i] then
                local file = not_alter_yet[i][1]
                local attr = not_alter_yet[i][2]
                if not file then break end
                if not fio_exists(file) then
                    db.awatcher.upd(
                        wid, file, true, FILE.DISAPPEARED_UNEXPECTEDLY
                    )
                    not_alter_yet[i] = nil
                else
                    local alter_lst = ''
                    local flf = fio_lstat(file)
                    local sha256
                    if not fio_is_dir(file) then
                        if flf.size ~= 0 then
                            local fh = io_open(file, 'r')
                            local cn = fh:read()
                            sha256 = dig_sha256(cn)
                            fh:close()
                        else
                            sha256 = ''
                        end
                    else
                        local lstdir = fio_listdir(file)
                        if not lstdir then
                            sha256 = ''
                        else
                            sha256 = dig_sha256(ut.tostring(lstdir))
                        end
                    end
                    if sha256 ~= attr.sha256 then
                        alter_lst = alter_lst .. FILE.CONTENT_ALTERATION
                    end
                    if flf.size ~= attr.size then
                        alter_lst = alter_lst .. FILE.SIZE_ALTERATION
                    end
                    if flf.ctime ~= attr.ctime then
                        alter_lst = alter_lst .. FILE.CHANGE_TIME_ALTERATION
                    end
                    if flf.mtime ~= attr.mtime then
                        alter_lst = alter_lst .. FILE.MODIFICATION_TIME_ALTERATION
                    end
                    if flf.uid ~= attr.uid then
                        alter_lst = alter_lst .. FILE.OWNER_ALTERATION
                    end
                    if flf.gid ~= attr.gid then
                        alter_lst = alter_lst .. FILE.GROUP_ALTERATION
                    end
                    if flf.inode ~= attr.inode then
                        if flf.gid ~= attr.gid then
                            alter_lst = alter_lst .. FILE.INODE_ALTERATION
                        end
                    end
                    if awhat == '1' and alter_lst ~= '' then
                        db.awatcher.upd(
                            wid, file, true, FILE.ANY_ALTERATION
                        )
                        not_alter_yet[i] = nil --Exclude item
                    else
                        if string_find(alter_lst, awhat) then
                            db.awatcher.upd(
                                wid, file, true, awhat
                            )
                            not_alter_yet[i] = nil --Exclude item
                        end
                    end
                end
                if db.awatcher.match(wid, awhat)>=nmatch then
                    is_over = true
                    break
                end
                fib_sleep(interval)
            end
        end
        if is_over then 
            break
        end
    end
    bfa_end:signal()
end

-- Remove duplicate values from a table
local function remove_duplicates(tbl)
    local hash = {}
    local answ = {}

    if #tbl==1 then return tbl end

    for _,v in ipairs(tbl) do
        if not hash[v] then
            answ[#answ+1] = v
            hash[v] = true
        end
    end
    return answ
end

--- Consolidate the watch list items
-- Expand patterns types if exists and Remove duplicates for FW Deletion
local function cons_watch_listd(wlist)

    local _wlist = remove_duplicates(wlist)

    local t = {}

    for _,v in pairs(_wlist) do
        if v ~= '' then
            if string_find(v, '*') then
                local pattern_result = fio_glob(v)
                --Merge pattern items result with t
                for _,nv in ipairs(pattern_result) do
                    t[#t+1] = nv
                end
            else
                t[#t+1] = v
            end
        end
    end

    if #t~=0 then
        return remove_duplicates(t)
    else
        return {}
    end

end

-- Determines if a file is stable in relation to its size and layout
-- If the size does not vary in the given conditions, then return true
local function is_stable_size(
    --[[require]] path,
    --[[optional]] interval,
    --[[optional]] iterations)

    local p_interval = interval or 1
    local p_iterations = iterations or 15

    local is_stable = false
    local fio_lstat = fio.lstat
    local r_size = fio_lstat(path).size --reference size

    local mssg

    local stable_iter = 0 --Stable iteration couter
    while true do
        local o_lstat = fio_lstat(path)
        local f_size
        if o_lstat then
            f_size = o_lstat.size
            if f_size == r_size then
                stable_iter = stable_iter +1
                if stable_iter > p_iterations then
                    is_stable = true
                    break
                else
                    fib_sleep(p_interval)
                end
            else
                stable_iter = 0
            end
        else
            --File dissapear
            mssg = FILE.DISAPPEARED_UNEXPECTEDLY
            is_stable = false
            break
        end
        r_size = f_size --Update the reference size
    end
    return is_stable, mssg
end

local bfc_end = fiber.cond() --Bulk file creacion end

local function bulk_file_creation(
    wid,
    bulk,
    maxwait,
    interval,
    minsize,
    stability,
    novelty,
    nmatch)

    fib_sleep(0.1)
    local fio_lexists = fio.path.lexists
    local fio_lstat = fio.lstat

    local ini = os_time()

    local nfy = bulk --not_found_yet
    local fnd = {}   --founded
    local nff = 0
    local nfp = 0

    local ch_cff = fiber.channel(BULK_CAPACITY)

    local function check_files_found(
        ch,
        _minsize,
        _stability,
        _novelty
    )
        while true do
            local data = ch:get()
            if data == nil then
                break
            end
            fiber.create(
                function()
                    if _novelty then
                        local lmod = fio_lstat(data).mtime
                        if not (lmod >= novelty[1] and lmod <= novelty[2]) then
                            db.awatcher.upd(
                                wid, data, false, FILE.IS_NOT_NOVELTY
                            )
                            return
                        end
                    end
                    if _stability then
                        local stble, merr = is_stable_size(
                            data,
                            stability[1],
                            stability[2]
                        )
                        if not stble then
                            db.awatcher.upd(
                                wid, data, false, FILE.UNSTABLE_SIZE
                            )
                            if merr then
                                db.awatcher.upd(wid, data, false, merr)
                            end
                            return
                        end
                    end
                    if _minsize then
                        if not (fio_lstat(data).size >= minsize) then
                            db.awatcher.upd(wid, data, false, FILE.UNEXPECTED_SIZE)
                            return
                        end
                    end
                    db.awatcher.upd(wid, data, true, FILE.HAS_BEEN_CREATED)
                end
            )
        end
    end

    fiber.create(
        check_files_found,
        ch_cff,
        minsize,
        stability,
        novelty
    )

    local has_pttn = false
    while ((os_time() - ini) < maxwait) do
        for k,v in pairs(nfy) do
            if not string_find(v, '*') then
                if fio_lexists(v) then
                    fnd[#fnd+1]=v
                    nfy[k] = nil
                    nff = nff + 1
                    if stability or minsize or novelty then
                        ch_cff:put(v, 0)
                    else
                        db.awatcher.upd(
                            wid, v, true, FILE.HAS_BEEN_CREATED
                        )
                    end
                end
            else
                has_pttn = true
                local pit = fio_glob(v) --pattern_items
                if #pit~=0 then
                    for _,u in pairs(pit) do
                        if not ut.is_valof(fnd, u) then
                            fnd[#fnd+1]=u
                            nfp = nfp + 1
                            if stability or minsize or novelty then
                                db.awatcher.add(wid, u)
                                ch_cff:put(u, 0)
                            else
                                db.awatcher.put(wid, u, true, FILE.HAS_BEEN_CREATED)
                            end
                        end
                    end
                end
            end
        end
        --Exit as soon as posible
        if (not has_pttn and nff>=nmatch) or db.awatcher.match(wid)>=nmatch then
            break
        end
        fib_sleep(interval)
    end
    --'MAXWAIT_TIMEOUT'
    bfc_end:signal()
end

--API Definition
local function file_deletion(
    --[[required]] wlist,
    --[[optional]] maxwait,
    --[[optional]] interval,
    --[[optional]] options)

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

    -- Consolidate the input watch list
    local cwlist = cons_watch_listd(wlist)
    local nfiles = #cwlist

    assert(
        nfiles ~= 0,
        OUTPUT.NOTHING_FOR_WATCH
    )

    local p_options = options or {sort = SORT_BY.NO_SORT, cases = 0, match = 0}

    local p_sort = p_options[1] or SORT_BY.NO_SORT
    local p_cases = p_options[2] or 0
    local _match = p_options[3] or 0

    if p_cases==0 then p_cases = nfiles end
    if _match==0 then _match = nfiles end

    assert(tonumber(p_cases), OUTPUT.N_CASES_NOT_VALID)
    assert(tonumber(_match), OUTPUT.N_MATCH_NOT_VALID)

    local cwlist_o = sort_files_by(cwlist, p_sort, p_cases)

    local _, wid = db.awatcher.new(ut.tostring(cwlist), 'FWD')

    local nbulks = math.floor(1 + nfiles/BULK_CAPACITY)
    local bulk_fibs = {} --Fiber list
    local pos = 0
    for i = 1, nbulks do
        local bulk = {}
        local val
        for j = 1, BULK_CAPACITY do
            pos = pos + 1
            val = cwlist_o[pos]
            if val then
                bulk[j] = val
                db.awatcher.add(wid, val, false, FILE.NOT_YET_DELETED)
            else
                break
            end
        end
        local bfid = fiber.create(
            bulk_file_deletion,
            wid,
            bulk,
            _maxwait,
            _interval,
            _match
        )
        bfid:name('file-watcher-bulk-d')
        bulk_fibs[i] = bfid
    end

    bfd_end:wait()

    --Cancel fibers
    for _, fib in pairs(bulk_fibs) do
        local fid = fiber.id(fib)
        pcall(fiber.cancel, fid)
    end

    return {wid=wid, ans=db.awatcher.endw(wid, _match, WATCHER.FILE_DELETION)}

end

--- File Watch for File Creations
--
local function file_creation(
    --[[required]] wlist,
    --[[optional]] maxwait,
    --[[optional]] interval,
    --[[optional]] minsize,
    --[[optional]] stability,
    --[[optional]] novelty,
    --[[optional]] nmatch)

    assert(
        wlist and (type(wlist)=='table') and (#wlist~=0),
        OUTPUT.WATCH_LIST_NOT_VALID
    )

    local w_maxwait = maxwait or WATCHER.MAXWAIT
    assert(
        type(w_maxwait)=='number' and w_maxwait > 0,
        OUTPUT.MAXWAIT_NOT_VALID
    )

    local w_interval = interval or WATCHER.INTERVAL
    assert(
        type(w_interval)=='number' and w_interval > 0,
        OUTPUT.INTERVAL_NOT_VALID
    )

    local fminsize = minsize or 0
    assert(
        fminsize and type(fminsize)=='number' and fminsize >= 0,
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

    local cwlist = remove_duplicates(wlist)
    local nfiles = #cwlist

    assert(
        nfiles ~= 0,
        OUTPUT.NOTHING_FOR_WATCH
    )

    local ematch = nmatch or nfiles -- match for all cases

    local _, wid = db.awatcher.new(ut.tostring(cwlist), 'FWC')

    local nbulks = math.floor(1 + nfiles/BULK_CAPACITY)
    local bulk_fibs = {} --Fiber list
    local pos = 0
    for i = 1, nbulks do
        local bulk = {}
        local val
        for j = 1, BULK_CAPACITY do
            pos = pos + 1
            val = cwlist[pos]
            if val then
                bulk[j] = val
                if not string_find(val, '*') then
                    db.awatcher.add(wid, val)
                else
                    db.awatcher.add(
                        wid, val, false, FILE.IS_PATTERN
                    )
                end
            else
                break
            end
        end
        local bfid = fiber.create(
            bulk_file_creation,
            wid,
            bulk,
            w_maxwait,
            w_interval,
            fminsize,
            stability,
            novelty,
            ematch
        )
        bfid:name('file-watcher-bulk-c')
        bulk_fibs[i] = bfid
    end

    bfc_end:wait()

    --Cancel fibers
    for _, fib in pairs(bulk_fibs) do
        local fid = fiber.id(fib)
        pcall(fiber.cancel, fid)
    end

    return {wid=wid, ans=db.awatcher.endw(wid, ematch)}

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

    -- Consolidate the input watch list
    local cwlist = cons_watch_listd(wlist)
    local nfiles = #cwlist

    assert(
        nfiles ~= 0,
        OUTPUT.NOTHING_FOR_WATCH
    )

    local _match = nmatch or nfiles
    local _, wid = db.awatcher.new(ut.tostring(cwlist), 'FWA')

    local fio_lstat = fio.lstat
    local dig_sha256 = dig.sha256
    local io_open = io.open
    local fio_is_dir = fio.path.is_dir
    local fio_listdir = fio.listdir
    local fio_exists = fio.path.lexists

    local nbulks = math.floor(1 + nfiles/BULK_CAPACITY)
    local bulk_fibs = {} --Fiber list
    local pos = 0
    for i = 1, nbulks do
        local bulk = {}
        local val
        local k = 0
        for j = 1, BULK_CAPACITY do
            pos = pos + 1
            val = cwlist[pos]
            local _sha256
            if val then
                if fio_exists(val) then
                    local flf = fio_lstat(val)
                    if not fio_is_dir(val) then
                        if flf.size ~= 0 then
                            local fh = io_open(val, 'r')
                            local cn = fh:read()
                            _sha256 = dig_sha256(cn)
                            fh:close()
                        else
                            _sha256 = ''
                        end
                    else
                        local lstdir = fio_listdir(val)
                        if not lstdir then
                            local message = {'Ignoring sha256 for', val, '-', errno.strerror()}
                            log.warn(table.concat(message, ' '))
                            _sha256 = ''
                        else
                            _sha256 = dig_sha256(ut.tostring(lstdir))
                        end
                    end
                    local as = {
                        sha256 = _sha256,
                        size = flf.size,
                        ctime = flf.ctime,
                        mtime = flf.mtime,
                        uid = flf.uid,
                        gid = flf.gid,
                        inode = flf.inode
                    }
                    k = k + 1
                    bulk[k] = {val, as}
                    db.awatcher.add(wid, val, false, FILE.NO_ALTERATION)
                else
                    db.awatcher.put(wid, val, false, FILE.NOT_EXISTS)
                end
            else
                break
            end
        end
        if bulk[1] then
            local bfid = fiber.create(
                bulk_file_alteration,
                wid,
                bulk,
                _awhat,
                _maxwait,
                _interval,
                _match
            )
            bfid:name('file-watcher-bulk-a')
            bulk_fibs[i] = bfid
        end
    end
    if bulk_fibs[1] then
        --Waiting for ended
        bfa_end:wait()
        --Cancel fibers
        for _, fib in pairs(bulk_fibs) do
            local fid = fiber.id(fib)
            pcall(fiber.cancel, fid)
        end
        return {wid=wid, ans=db.awatcher.endw(wid, _match, _awhat)}
    end
    --Nothing for watch
    return {wid=wid, ans=false}
end

-- Export API functions

local file = {}
file.deletion = file_deletion
file.creation = file_creation
file.alteration = file_alteration

return file