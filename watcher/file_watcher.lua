#!/usr/bin/env tarantool
------------
-- File Watcher.
-- Watcher for files, directories, objects and services.
-- ...
-- @module watcher
-- @author hernandez, raciel
-- @license MIT
-- @copyright Raciel Hernández 2019

local strict = require("strict")
local fiber = require("fiber")
local fio = require("fio")

local os_time = os.time
local fib_sleep = fiber.sleep
local fio_glob = fio.glob

local db = require('db.engine')
local ut = require('util')

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
        return (FW_PREFIX .. "_DIR")
    elseif fio_path.is_file(path) then
        return (FW_PREFIX .. "_FILE")
    elseif fio_path.is_link(path) then
        return (FW_PREFIX .. "_LINK")
    elseif fio_stat(path) and fio_stat(path):is_sock() then
        return (FW_PREFIX .. "_SOCK")
    elseif fio_stat(path) and fio_stat(path):is_reg() then
        return (FW_PREFIX .. "_REG")
    elseif fio_stat(path) and fio_stat(path):is_fifo() then
        return (FW_PREFIX .. "_FIFO")
    elseif fio_stat(path) and fio_stat(path):is_blk() then
        return (FW_PREFIX .. "_BLOCK")
    elseif fio_stat(path) and fio_stat(path):is_chr() then
        return (FW_PREFIX .. "_CHR")
    elseif string.find(path, "*") then
        return (FW_PREFIX .. "_PATTERN")
    else --Desconocido o no determindado (porque no existe)
        return (FW_PREFIX .. "_UNKNOWN")
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
    if not path or str_strip(path) == "" then
        return false, "FW_PATH_ISEMPTY", path
    else
        p_path = str_strip(path)
    end

    local p_maxwait = maxwait
    local p_interval = interval

    if interval > p_maxwait then p_interval = p_maxwait end

    local fw_type = fw_get_type(p_path)
    local fio_exists = fio.path.lexists

    if not fio_exists(p_path) then
        return true, fw_type .. "_NOT_EXISTS", p_path
    else
        --Exists, then watch for deletion
        local answ = false
        local mssg = fw_type .. "_NOT_DELETED"
        local ini = os_time()
        while (os_time() - ini < p_maxwait) do
            if not fio_exists(p_path) then
                answ = true
                mssg = fw_type .. "_DELETED"
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
        return true, "FW_ALL_DELETED", match, nomatch

    elseif ntrue >= nmatch then
        -- The number of eliminations is equal to or greater than expected
        return true, "FW_MATCH_DELETED", match, nomatch

    elseif (ntrue > 0) and (ntrue < nmatch) then
        return false, "FW_MATCH_NOT_DELETED", match, nomatch

    else
        return false, "FW_NOTHING_DELETED", match, nomatch
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
        return false, "FW_GROUP_IS_NULL"
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
        if fw_gettype(v)=="FW_PATTERN" then
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
            mssg = "DISAPPEARED_UNEXPECTEDLY"
            is_stable = false
            break
        end
        r_size = f_size --Update the reference size
    end
    return is_stable, mssg
end

-- @param path string: File Path
-- @param maxwait number
-- @param interval number
-- @param minsize number    : Minimum expected size to validate.
-- From this value the file growth check is activated.
-- @param grow_interval     : Growth check interval.
-- @param iterations number : Number of interactions to confirm stable size.
-- For each of these iterations the file size is the same.
-- @param novelty table     : Data for archive novelty check
-- When the same file is overwritten, activate this option to know if it is a new creation.
local function single_file_creation(
    --[[required]] path,
    --[[optional]] maxwait,
    --[[optional]] interval,
    --[[optional]] minsize,
    --[[optional]] check_stable_size,
    --[[optional]] check_interval,
    --[[optional]] max_iterations,
    --[[optional]] novelty,
    --[[optional]] initio)

    --Validate path input
    local p_path
    if not path or string.strip(path) == "" then
        return false, "FW_PATH_IS_EMPTY", path
    else
        p_path = string.strip(path)
    end

    --TODO: Remove these validations and delegate to the API
    local p_maxwait = maxwait
    local p_interval = interval
    local p_minsize = minsize or 0
    local p_check_stable_size = check_stable_size or FW_DEFAULT.CHECK_STABLE_SIZE
    local p_check_interval = check_interval or 1
    local p_max_iterations = max_iterations or 15
    local p_novelty = novelty

    --Validates the values of p_novelty
    -- p_novelty[1] --Date from
    -- p_novelty[2] --Date to

    if interval > p_maxwait then p_interval = p_maxwait end

    local fio_lexists = fio.path.lexists
    local fio_lstat = fio.lstat

    local prefix = ""
    local sufix = ""
    local answ

    -- Supouse that not exists
    --  then watch for creation
    local ini = initio or os_time()

    while (os_time() - ini < p_maxwait) do
        if not fio_lexists(p_path) then
            answ = false
            prefix = "NOT_CREATED"
            sufix = "YET"
        else
            prefix = "CREATED"
            if fio_lstat(p_path).size >= p_minsize then
                answ = true
                sufix = "MIN_SIZE_OK"
                break
            else
                sufix = "SIZE_NOT_EXPECTED"
                answ = false
            end
        end
        fib_sleep(p_interval)
    end
    -- check size
    if answ == true then -- when the file has been created
        if p_check_stable_size == "YES" then
            local is_stable, merr = is_stable_size(p_path,
                p_check_interval,
                p_max_iterations
            )
            if not is_stable then
                sufix = "INESTABLE_SIZE" --During p_check_interval and p_max_iterations
                if merr then sufix = merr end
                answ = false
            end
        end

        --check novelty
        if p_novelty then
            local f_lmod = fio_lstat(p_path).mtime --last modified date
            --TODO: @fixme: If only one novelty value is provided, then cloning the other
            if not (f_lmod >= p_novelty[1] and f_lmod <= p_novelty[2]) then
                sufix = "NOT_NOVELTY"
                answ = false
            else
                answ = true
            end
        end
    end

    local fw_gettype = fw_get_type
    --local mssg = fw_gettype(p_path) .. "_" .. prefix .. "_" .. sufix
    local mssg_fmt = "%s_%s_%s"
    local mssg = mssg_fmt:format(
        fw_gettype(p_path),
        prefix,
        sufix
    )
    mssg = mssg:gsub("s_+", "") --Delete the last _ if exists

    return {answ, mssg, p_path}

end

local function bulk_file_ceation(
    bulk,
    maxwait,
    interval,
    minsize,
    stability,
    novelty)

    local fio_lexists = fio.path.lexists
    local fio_lstat = fio.lstat

    local ini = os_time()

    local niw = #bulk
    local nfy = bulk --not_found_yet
    local fnd = {}   --founded
    local nff = 0
    local nfp = 0

    local BULK_CAPACITY = 1000000

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
            if _novelty then
                local lmod = fio_lstat(data).mtime
                if not (lmod >= novelty[1] and lmod <= novelty[2]) then
                    print("_CREATED_BUT_NOT_NOVELTY")
                    break
                end
            end
            if _stability then
                fiber.create(
                    function()
                        local stble, merr = is_stable_size(data,
                        stability[1],
                        stability[2])
                        if not stble then
                            print("INESTABLE_SIZE")
                            if merr then
                                print(merr)
                            end
                            return
                        end
                        if _minsize then
                            if not (fio_lstat(data).size >= minsize) then
                                print("_CREATED_BUT_SIZE_NOT_EXPECTED")
                            end
                        end
                    end
                )
            end
        end
    end

    local fib_check = fiber.create(
        check_files_found,
        ch_cff,
        minsize,
        stability,
        novelty
    )

    local has_pttn = false
    while (os_time() - ini < maxwait) do
        for k,v in pairs(nfy) do
            if fw_get_type(v)~="FW_PATTERN" then
                if fio_lexists(v) then
                    fnd[#fnd+1]=v
                    nfy[k] = nil
                    nff = nff + 1
                    if stability or minsize or novelty then
                        ch_cff:put(v, 0)
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
                                ch_cff:put(u, 0)
                            end
                        end
                    end
                end
            end
        end
        if not has_pttn and nff==niw then
            break
        end
        fib_sleep(interval)
    end
end

--local fib=fiber.create(single_file_deletion,'/tmp/example.txt', 60, 1)

-- FW API ===================================================================
-- options = {"SORT_FILE_ASC", "ALL", "ALL"}
local function file_deletion(
    --[[required]] watch_list,
    --[[optional]] maxwait,
    --[[optional]] interval,
    --[[optional]] options)

    local is_valid_wlst = watch_list and (type(watch_list)=="table") and (#watch_list~=0)
    assert(is_valid_wlst, "FW_WATCHLIST_NOT_VALID")

    local p_maxwait = maxwait or FW_DEFAULT.MAXWAIT
    local is_valid_maxwait = type(p_maxwait)=="number" and p_maxwait > 0 and p_maxwait < 1000000
    assert(is_valid_maxwait, "FW_MAXWAIT_NOT_VALID")

    local p_interval = interval or FW_DEFAULT.INTERVAL
    local is_valid_interval = type(p_interval)=="number" and p_interval > 0 and p_interval < 1000000
    assert(is_valid_interval, "FW_INTERVAL_NOT_VALID")

    local p_options = options or {sort=FW_VALUES.SORT.ALPHA_ASC, cases = "ALL", match = 'ALL'}

    local p_sort = p_options[1] or FW_DEFAULT.SORT
    local p_cases = p_options[2] or "ALL"
    local p_match = p_options[3] or "ALL"

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

    if p_cases=="ALL" then p_cases = nitems end
    if p_match=="ALL" then p_match = nitems end

    assert(tonumber(p_cases), "FW_NCASES_NOT_VALID")
    assert(tonumber(p_match), "FW_NMATCH_NOT_VALID")

    if p_sort==FW_DEFAULT.SORT and (p_cases=="ALL" or p_cases==#watch_list_cons) then
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

local function group_file_creation(
    wlst,
    maxwait,
    interval,
    minsize,
    check_stable_size,
    check_interval,
    max_iterations,
    novelty,
    nmatch)

    local ilst = {} --File list
    local plst = {} --List of patterns

    local what = ut.tostring(wlst)
    local ok, wid = db.awatcher.new(what, "FWC")
    assert(ok, 'FW_ERR_WID_NOT_CREATED')

    --Separate patterns and items hard files
    for _,v in pairs(wlst) do
        if fw_get_type(v)~="FW_PATTERN" then
            ilst[#ilst+1]=v
        else
            plst[#plst+1]=v
        end
    end

    local p_match = nmatch or (#ilst + #plst)
    local tmatch = 0

    local function fw_fib_consumer(ch)
        fiber.sleep(0)
        local task = ch:get()
        db.awatcher.update(wid, task[3], task[1], task[2])
        print(task[3])
        tmatch=tmatch+1
        if tmatch>=p_match then
            db.awatcher.close(wid)
            return
        end
    end

    local ini = os_time() --Beginning of the interval

    local function fw_fib_producer(ch, path)
        local task = single_file_creation(
            path,
            maxwait,
            interval,
            minsize,
            check_stable_size,
            check_interval,
            max_iterations,
            novelty,
            ini
            )
            ch:put(task)
    end

    if #ilst~=0 then

        local nitems = #ilst
        local fw_chanel = fiber.channel(nitems)

        for _,v in pairs(ilst) do
            fiber.create(fw_fib_consumer, fw_chanel)
            local fob = fiber.create(fw_fib_producer, fw_chanel, v)
            local ok = db.awatcher.add(wid, fob:id(), v)
            assert(ok, 'FW_ERR_CANT_ADD_WATCHABLE')
        end

    end

    --Solution to the items that are patterns
    if #plst~=0 then
        local nchan = 100
        local fw_chanel_p = fiber.channel(nchan)

        --Get files from all patterns
        local nitems = {} --New files detected
        while (os_time() - ini < maxwait) do
            for _,v in pairs(plst) do
                local pttrn_result = fio_glob(v)
                if #pttrn_result~=0 then
                    for _,p in pairs(pttrn_result) do
                        if not ut.is_valof(nitems, p) then
                            nitems[#nitems+1]=p
                            --Create consumer
                            --TODO: @fixme: Controler n fiber creation
                            --      for mem consumer
                            fiber.create(fw_fib_consumer, fw_chanel_p)
                            local fob = fiber.create(fw_fib_producer, fw_chanel_p, p)
                            local ok = db.awatcher.add(wid, fob:id(), v)
                            assert(ok, 'FW_ERR_CANT_ADD_WATCHABLE')
                        end
                    end
                end
            end
        end

        --TODO: @fixme: How to summarize this result in the output,
        -- i.e. patterns with no watcher result
        if #nitems==0 then
            print('No pattern math file watchers')
        end
    end

    return wid

end

--- File Watch for File Creations
--
-- fw.file_creation({'/tmp/file_d'}, 10, 1, 0, {"YES", 1, 15}, nil)
local function file_creation(
    --[[required]] watch_list,
    --[[optional]] maxwait,
    --[[optional]] interval,
    --[[optional]] minsize,
    --[[optional]] stability,
    --[[optional]] novelty,
    --[[optional]] nmatch)

    local is_valid_wlst = watch_list and (type(watch_list)=="table") and (#watch_list~=0)
    assert(is_valid_wlst, "FW_WATCHLIST_NOT_VALID")

    local p_maxwait = maxwait or FW_DEFAULT.MAXWAIT
    local is_valid_maxwait = type(p_maxwait)=="number" and p_maxwait > 0 and p_maxwait < 1000000
    assert(is_valid_maxwait, "FW_MAXWAIT_NOT_VALID")

    local p_interval = interval or FW_DEFAULT.INTERVAL
    local is_valid_interval = type(p_interval)=="number" and p_interval > 0 and p_interval < 1000000
    assert(is_valid_interval, "FW_INTERVAL_NOT_VALID")

    local p_minsize = minsize or 0
    local is_valid_minsize = type(p_minsize)=="number" and p_interval >= 0
    assert(is_valid_minsize, "FW_MINSIZE_NOT_VALID")

    local p_check_stable_size, p_check_interval, p_max_iterations
    if stability then
        local p_stability = stability
        local is_valid_stability = type(p_stability)=="table" and (#p_stability~=0)
        assert(is_valid_stability, "FW_STABILITY_NOT_VALID")
        if p_stability[1] then
            p_check_stable_size = p_stability[1]
        else
            p_check_stable_size = FW_DEFAULT.CHECK_STABLE_SIZE
        end
        if p_stability[2] then
            p_check_interval = p_stability[2]
            local is_valid_check_interval = type(p_check_interval)=="number" and (p_check_interval>0)
            assert(is_valid_check_interval, "CHECK_INTERVAL_NOT_VALID")
        else
            p_check_interval = FW_DEFAULT.CHECK_INTERVAL
        end
        if p_stability[3] then
            p_max_iterations = p_stability[3]
            local is_valid_max_iterations = type(p_max_iterations)=="number" and (p_max_iterations>0)
            assert(is_valid_max_iterations, "ITERATIONS_NOT_VALID")
        else
            p_max_iterations = FW_DEFAULT.ITERATIONS
        end
    end

    local p_novelty, p_time_from, p_time_until
    if novelty then
        p_novelty = novelty
        local is_valid_novelty = type(p_novelty)=="table" and (#p_novelty~=0)
        assert(is_valid_novelty, "FW_NOVELTY_NOT_VALID")
        if p_novelty[1] then
            p_time_from = p_novelty[1]
            local is_valid_time_from = type(p_time_from)=="number"
            assert(is_valid_time_from, "FW_TME_FROM_NOT_VALID")
        end
        if p_novelty[2] then
            p_time_until = p_novelty[2]
            local is_valid_time_until = type(p_time_until)=="number"
            assert(is_valid_time_until, "FW_TME_UNTIL_NOT_VALID")
        end
    end

    -- Remove duplicate item list from input watch_list
    local c_watch_list = remove_duplicates(watch_list)
    local nitems = #c_watch_list

    if nitems==1 and fw_get_type(c_watch_list[1])~="FW_PATTERN" then
        return single_file_creation(
            c_watch_list[1],
            p_maxwait,
            p_interval,
            p_minsize,
            p_check_stable_size,
            p_check_interval,
            p_max_iterations,
            p_novelty
        )
    end

    -- For Bulk file creation
    local p_nmatch = nmatch or nitems -- match for all cases

    local fwid = group_file_creation(
        c_watch_list,
        p_maxwait,
        p_interval,
        p_minsize,
        p_check_stable_size,
        p_check_interval,
        p_max_iterations,
        p_novelty,
        p_nmatch
    )

    print(fwid)

    --//TODO: Me quedé por acá
    --  Hay que verificar la salida según match esperado.
    -- Esto puede ser en una fibra consumidora.

end

--file_creation({'/tmp/file_d','/tmp/file_c'}, 3, 1, 0, {"NO", 1, 15})

local function file_alteration(x)
    print(x)
end

-- Export API functions
return {
    deletion = file_deletion,
    creation = file_creation,
    alteration = file_alteration,
    bfc = bulk_file_ceation
}