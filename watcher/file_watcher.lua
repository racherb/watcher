#!/usr/bin/env tarantool
------------
-- File Watcher.
-- Watcher for files, directories, objects and services.
-- ...
-- @module watcher
-- @author hernandez, raciel
-- @license MIT
-- @copyright Raciel Hernández 2019

local strict = require('strict')
local fiber = require('fiber')
local fio = require('fio')

local os_time = os.time
local fib_sleep = fiber.sleep
local fio_glob = fio.glob

local db = require('db.engine')
local ut = require('util')

local CREATION = require('types.file').CREATION
local OUTPUT = require('types.file').OUTPUT

db.start()

strict.on()

-- FW: File Watcher
-- File Watchers for files, folders, links and registers
-- file_deletion    : File delection watcher
-- file_creation    : File creation watcher
-- file_alteration  : File alteration watcher fio.lstat(path).mtime
-- file_access      : File Access watcher para chequear si fue accedido en una fecha
--                    fio.lstat(path).atime
-- file_mode        : Detects change of file permissions
--                    fio.lstat(path).mode
-- file_users       : Detects uid and gid changes (user owner and group)
--
-- RW: Record Watcher
-- record_deletion  : Record deletion (Registers)
-- record_creation  : Record creation
-- record_alteration: Record alter

local FW_DEFAULT = {
    PREFIX = 'FW',
    ACTION = 'CREATION',
    MAXWAIT = 60,
    INTERVAL = 0.5,
    SORT = 'NO_SORT',
    CHECK_STABLE_SIZE = 'YES',
    CHECK_INTERVAL = 0.5,
    ITERATIONS = 10
}

local FW_VALUES = {
    SORT = {
        ALPHA_ASC = 'ALPHA_ASC',
        ALPHA_DSC = 'ALPHA_DSC',
        MTIME_ASC = 'MTIME_ASC',
        MTIME_DSC = 'MTIME_DSC'
    }
}

local BULK_CAPACITY = 1000000

--- Get Type for File Watcher
-- Get the type of file, directory or link
-- through either this function or load_local_manifest.
-- @param path string   : Path or pathname for the object.
-- @return string       : Posible return values are
-- FW_DIR Directory
-- FW_FILE File
-- FW_LINK Link
-- FW_UNKNOW Unknow
-- FW_PATTERN
local function fw_get_type(path)
    local fio_path = fio.path
    local fio_stat = fio.stat
    local FW_PREFIX = FW_DEFAULT.PREFIX
    if fio_path.is_dir(path) then
        return (FW_PREFIX .. '_DIR')
    elseif fio_path.is_file(path) then
        return (FW_PREFIX .. '_FILE')
    elseif fio_path.is_link(path) then
        return (FW_PREFIX .. '_LINK')
    elseif fio_stat(path) and fio_stat(path):is_sock() then
        return (FW_PREFIX .. '_SOCK')
    elseif fio_stat(path) and fio_stat(path):is_reg() then
        return (FW_PREFIX .. '_REG')
    elseif fio_stat(path) and fio_stat(path):is_fifo() then
        return (FW_PREFIX .. '_FIFO')
    elseif fio_stat(path) and fio_stat(path):is_blk() then
        return (FW_PREFIX .. '_BLOCK')
    elseif fio_stat(path) and fio_stat(path):is_chr() then
        return (FW_PREFIX .. '_CHR')
    elseif string.find(path, '*') then
        return (FW_PREFIX .. '_PATTERN')
    else --Desconocido o no determindado (porque no existe)
        return (FW_PREFIX .. '_UNKNOWN')
    end
end

--- Watcher a Single File Delection
-- Detects deletion of files, directories or links
-- @param path string   : File path, directory or link
-- @param maxwait int   : Maximum waiting time
-- @param interval int  : Checking frequency
-- @return ok boolean   : frue or false for check deletion
-- @return mssg string  : Main message code
-- FW_FILE_NOT_EXISTS   : The file does not exist at the time of verification
-- FW_FILE_DELETED      : The file has been deleted
-- FW_FILE_NOT_DELETED  : The file has not been deleted in the expected time
-- FW_DIR_NOT_EXISTS    : The folder does not exist at the time of checking
-- FW_DIR_DELETED       : The folder has been deleted
-- FW_DIR_NOT_DELETED   : The folder has not been deleted in the expected time
-- FW_LINK_DELETED      : The link has been removed
-- FW_LINK_NOT_EXISTS   : The link does not exist at the time of verification
-- FW_LINK_NOT_DELETED  : The link has not been removed in the expected time
-- FW_UNKNOW_NOT_EXISTS : The incognito type does not exist
-- FW_PATH_ISEMPTY      : The folder is empty
-- @return path string: Path for check object
local function single_file_deletion(
    --[[required]] path,
    --[[optional]] maxwait,
    --[[optional]] interval)

    --Validate path input
    local p_path
    local str_strip = string.strip
    if not path or str_strip(path) == '' then
        return false, 'FW_PATH_ISEMPTY', path
    else
        p_path = str_strip(path)
    end

    local p_maxwait = maxwait
    local p_interval = interval

    if interval > p_maxwait then p_interval = p_maxwait end

    local fw_type = fw_get_type(p_path)
    local fio_exists = fio.path.lexists

    if not fio_exists(p_path) then
        return true, fw_type .. '_NOT_EXISTS', p_path
    else
        --Exists, then watch for deletion
        local answ = false
        local mssg = fw_type .. '_NOT_DELETED'
        local ini = os_time()
        while (os_time() - ini < p_maxwait) do
            if not fio_exists(p_path) then
                answ = true
                mssg = fw_type .. '_DELETED'
                break
            end
            fib_sleep(p_interval)
        end
        return answ, mssg, p_path
    end
end

-- Add the last date of file modification
local function add_lst_modif( tbl )
    local t = {}
    local fio_lstat = fio.lstat
    for _, v in pairs( tbl ) do
        local lst_mod = fio_lstat(v).mtime
        t[#t+1] = {v, lst_mod}
    end
    return t
end

-- Take n items from a table
local function take_n_items(
    --[[required]] tbl,
    --[[required]] n )

    if n == 0 then
        return tbl --Take all items
    elseif n == 1 then
        return { tbl[1] } --Take the first
    else
        --Take the n first items
        local t = {}
        for i = 1, n, 1 do
            t[#t+1] = tbl[i]
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
    if take_n > #flst then take_n = #flst end

    if sort_by == FW_DEFAULT.SORT then
        return take_n_items(flst, take_n)
    elseif sort_by == FW_VALUES.SORT.ALPHA_ASC then
        table.sort(
            flst,
            function(a, b)
                return a < b
            end
        )
        return take_n_items(flst, take_n)

    elseif sort_by == FW_VALUES.SORT.ALPHA_DSC then
        table.sort(
            flst,
            function(a, b)
                return a > b
            end
        )
        return take_n_items(flst, take_n)

    elseif sort_by == FW_VALUES.SORT.MTIME_ASC then
        local flst_ex = add_lst_modif(flst)
        table.sort(
            flst_ex,
            function(a, b)
                return a[2] < b[2]
            end
        )
        return take_n_items(flst_ex, take_n)

    elseif sort_by == FW_VALUES.SORT.MTIME_DSC then
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

--- File Watcher Check End Status
-- Determines whether the fw completion conditions are met for the group
-- FW_GROUP_ALL_DELETED
-- FW_GROUP_MATCH_DELETED
-- FW_GROUP_MATCH_NOT_DELETED
-- FW_GROUP_NOTHING_DELETED
local function fw_check_end(
    --[[required]] tbl,
    --[[required]] nmatch)

    local ntrue = 0
    local match = {}
    local nomatch = {}

    --TODO: @fixme: Implement closure so that match cases are not validated again.
    --      Benefits: Checks a snapshot and avoids errors in highly dynamic
    --      file creation and deletion environments.
    for _, v in pairs(tbl) do -- Count the true
        if v[2] == true then
            ntrue = ntrue + 1
            match[#match+1] = v[1][1]
        else
            nomatch[#nomatch+1] = v[1][1]
        end
    end

    if (ntrue == #tbl) then
        -- The entire group has been eliminated
        return true, OUTPUT.ALL_DELETED, match, nomatch

    elseif ntrue >= nmatch then
        -- The number of eliminations is equal to or greater than expected
        return true, OUTPUT.MATCH_DELETED, match, nomatch

    elseif (ntrue > 0) and (ntrue < nmatch) then
        return false, OUTPUT.MATCH_NOT_DELETED, match, nomatch

    else
        return false, OUTPUT.NOTHING_DELETED, match, nomatch
    end
end

-- Updates the status for each file in the table
-- ..
local function update_exists_file(tbl)
    --TODO: @fixme: Optimize, update only those tbl cases that are false
    local answ = {}
    local fio_exists = fio.path.lexists
    local pathf
    for k, v in pairs(tbl) do
        if type(v[1])~='table' then pathf = v[1] else pathf = v[1][1] end
        if fio_exists(pathf) then
            answ[k] = {v, false}
        else
            answ[k] = {v, true}
        end
    end
    return answ
end

--- Watcher for Group File Deletion
local function group_file_deletion(
    --[[required]] grp,
    --[[optional]] maxwait,
    --[[optional]] interval,
    --[[optional]] nmatch)

    if #grp == 0 then
        return false, 'FW_GROUP_IS_NULL'
    end

    local p_maxwait = maxwait or FW_DEFAULT.MAXWAIT
    local p_interval = interval or FW_DEFAULT.INTERVAL
    local p_nmatch = nmatch or #grp

    if p_interval > p_maxwait then p_interval = p_maxwait end

    --Initializes false checklist
    local lst = {}
    for _, v in pairs(grp) do
        lst[#lst+1] = {v, false} --table.insert(lst, {v, false})
    end

    local answ, mssg, match, nomatch
    local ini = os_time()
    while (os_time() - ini < p_maxwait) do
        local lstupd = update_exists_file(lst)
        answ, mssg, match, nomatch = fw_check_end(lstupd, p_nmatch)
        if answ then
            break
        else
            fib_sleep(p_interval)
        end
    end
    return answ, mssg, match, nomatch
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
local function cons_watch_listd(watch_list)

    local p_watch_list = remove_duplicates(watch_list)

    local t = {}
    local fw_gettype = fw_get_type

    for _,v in pairs(p_watch_list) do
        if fw_gettype(v)=='FW_PATTERN' then
            local pattern_result = fio_glob(v)
            --Merge pattern items result with t
            for _,nv in ipairs(pattern_result) do
                t[#t+1] = nv
            end
        else
            t[#t+1] = v
        end
    end

    return remove_duplicates(t)

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

    local stable_iter = 0 --Iteraciones estables
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
            mssg = CREATION.DISAPPEARED_UNEXPECTEDLY
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
                                wid, data, false, CREATION.IS_NOT_NOVELTY
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
                                wid, data, false, CREATION.UNSTABLE_SIZE
                            )
                            if merr then
                                db.awatcher.upd(wid, data, false, merr)
                            end
                            return
                        end
                    end
                    if _minsize then
                        if not (fio_lstat(data).size >= minsize) then
                            db.awatcher.upd(wid, data, false, CREATION.UNEXPECTED_SIZE)
                            return
                        end
                    end
                    db.awatcher.upd(wid, data, true, CREATION.HAS_BEEN_CREATED)
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
            if fw_get_type(v)~='FW_PATTERN' then
                if fio_lexists(v) then
                    fnd[#fnd+1]=v
                    nfy[k] = nil
                    nff = nff + 1
                    if stability or minsize or novelty then
                        ch_cff:put(v, 0)
                    else
                        db.awatcher.upd(
                            wid, v, true, CREATION.HAS_BEEN_CREATED
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
                                db.awatcher.put(wid, u)
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
    --[[required]] watch_list,
    --[[optional]] maxwait,
    --[[optional]] interval,
    --[[optional]] options)

    assert(
        watch_list and (type(watch_list)=='table') and (#watch_list~=0),
        OUTPUT.WATCH_LIST_NOT_VALID
    )

    local p_maxwait = maxwait or FW_DEFAULT.MAXWAIT
    assert(
        type(p_maxwait)=='number' and p_maxwait > 0,
        OUTPUT.MAXWAIT_NOT_VALID
    )

    local p_interval = interval or FW_DEFAULT.INTERVAL
    assert(
        type(p_interval)=='number' and p_interval > 0,
        OUTPUT.INTERVAL_NOT_VALID
    )

    local p_options = options or {sort=FW_VALUES.SORT.ALPHA_ASC, cases = 'ALL', match = 'ALL'}

    local p_sort = p_options[1] or FW_DEFAULT.SORT
    local p_cases = p_options[2] or 'ALL'
    local p_match = p_options[3] or 'ALL'

    -- Consolidate the input watch list
    local watch_list_cons = cons_watch_listd(watch_list)
    local nitems = #watch_list_cons

    if nitems==1 then
        return single_file_deletion(
            watch_list_cons[1],
            p_maxwait,
            p_interval
        )
    end

    if p_cases=='ALL' then p_cases = nitems end
    if p_match=='ALL' then p_match = nitems end

    assert(tonumber(p_cases), OUTPUT.N_CASES_NOT_VALID)
    assert(tonumber(p_match), OUTPUT.N_MATCH_NOT_VALID)

    if p_sort==FW_DEFAULT.SORT and (p_cases=='ALL' or p_cases==#watch_list_cons) then
        return group_file_deletion(
            watch_list_cons,
            p_maxwait,
            p_interval,
            p_match
        )
    end

    local watch_list_ord
    watch_list_ord = sort_files_by(watch_list_cons, p_sort, p_cases)

    return group_file_deletion(
        watch_list_ord,
        p_maxwait,
        p_interval,
        p_match
    )

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

    local w_maxwait = maxwait or FW_DEFAULT.MAXWAIT
    assert(
        type(w_maxwait)=='number' and w_maxwait > 0,
        OUTPUT.MAXWAIT_NOT_VALID
    )

    local w_interval = interval or FW_DEFAULT.INTERVAL
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
    local ematch = nmatch or nfiles -- match for all cases

    local _, wid = db.awatcher.new(ut.tostring(cwlist), 'FWC')

    local nbulks = math.floor(1 + nfiles/BULK_CAPACITY)
    local bulk_fibs = {} --Fiber list
    local pos = 0
    for i = 1, nbulks do
        local bulk = {}
        local val
        for j = pos, BULK_CAPACITY do
            pos = pos + 1
            val = cwlist[pos]
            if val then
                bulk[j] = val
                if not string.find(val, '*') then
                    db.awatcher.add(wid, val)
                else
                    db.awatcher.add(
                        wid, val, false, CREATION.FILE_PATTERN
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

    return db.awatcher.endw(wid, ematch)

end

local function file_alteration(x)
    print(x)
end

-- Export API functions
return {
    deletion = file_deletion,
    creation = file_creation,
    alteration = file_alteration
}