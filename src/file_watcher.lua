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

local pairs = pairs
local ipairs = ipairs
local type = type

local os_time = os.time
local string_find = string.find
local fib_sleep = fiber.sleep
local fio_glob = fio.glob
local fio_is_dir = fio.path.is_dir
local fio_listdir = fio.listdir
local table_sort = table.sort

local db = require('db.engine')
local ut = require('util')

local FILE = require('types.file').FILE
local WATCHER = require('types.file').WATCHER
local SORT = require('types.file').SORT

local db_awatcher = db.awatcher

local prompt = 'watcher>'

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

local BULK_CAPACITY = 1e6

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
        if type(tbl[1])=='table' then
            return { tbl[1][1] }
        else
            return { tbl[1] }
        end
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
    --[[required]] sort_by,
    --[[required]] take_n)

    local size = #flst

    if take_n == 0 then return {} end
    if size == 0 then return flst end
    if take_n > size or not take_n then take_n = size end

    if #flst <= 1 then
        return flst
    end

    if sort_by == SORT.NO_SORT then
        return take_n_items(flst, take_n)
    elseif sort_by == SORT.ALPHA_ASC then
        table_sort(
            flst,
            function(a, b)
                return a < b
            end
        )
        return take_n_items(flst, take_n)

    elseif sort_by == SORT.ALPHA_DSC then
        table_sort(
            flst,
            function(a, b)
                return a > b
            end
        )
        return take_n_items(flst, take_n)

    elseif sort_by == SORT.MTIME_ASC then
        local flst_ex = add_lst_modif(flst)
        table_sort(
            flst_ex,
            function(a, b)
                return a[2] < b[2]
            end
        )

        return take_n_items(flst_ex, take_n)

    elseif sort_by == SORT.MTIME_DSC then
        local flst_ex = add_lst_modif(flst)
        table_sort(
            flst_ex,
            function(a, b)
                return a[2] > b[2]
            end
        )
        return take_n_items(flst_ex, take_n)
    end
end

local BULK_FILE_DELETION_END = fiber.cond() --Bulk file deletion end

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
                db_awatcher.upd(
                    wid, file, true, FILE.DELETED
                )
                print(prompt..'FILE_DELETED:' ..file)
                notdelyet[i] = nil
            end
        end
        if db_awatcher.match(wid, WATCHER.FILE_DELETION)>=nmatch then
            break
        end
        fib_sleep(interval)
    end
    BULK_FILE_DELETION_END:signal()
end

local BULK_FILE_ALTERATION_END = fiber.cond() --Bulk file alteration end

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
                    db_awatcher.upd(
                        wid, file, true, FILE.DISAPPEARED_UNEXPECTEDLY
                    )
                    print(prompt..'FILE_DISAPPEARED_UNEXPECTEDLY:' ..file)
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
                    local alter
                    if sha256 ~= attr.sha256 then
                        alter_lst = string.format(
                            '%s%s', alter_lst, FILE.CONTENT_ALTERATION
                        )
                        alter = 'FILE_CONTENT_ALTERATION'
                    end
                    if flf.size ~= attr.size then
                        alter_lst = string.format(
                            '%s%s', alter_lst, FILE.SIZE_ALTERATION
                        )
                        alter = 'FILE_SIZE_ALTERATION'
                    end
                    if flf.ctime ~= attr.ctime then
                        alter_lst = string.format(
                            '%s%s', alter_lst, FILE.CHANGE_TIME_ALTERATION
                        )
                        alter = 'FILE_CHANGE_TIME_ALTERATION'
                    end
                    if flf.mtime ~= attr.mtime then
                        alter_lst = string.format(
                            '%s%s', alter_lst, FILE.MODIFICATION_TIME_ALTERATION
                        )
                        alter = 'FILE_MODIFICATION_TIME_ALTERATION'
                    end
                    if flf.uid ~= attr.uid then
                        alter_lst = string.format(
                            '%s%s', alter_lst, FILE.OWNER_ALTERATION
                        )
                        alter = 'FILE_OWNER_ALTERATION'
                    end
                    if flf.gid ~= attr.gid then
                        alter_lst = string.format(
                            '%s%s', alter_lst, FILE.GROUP_ALTERATION
                        )
                        alter = 'FILE_GROUP_ALTERATION'
                    end
                    if flf.inode ~= attr.inode then
                        alter_lst = string.format(
                            '%s%s', alter_lst, FILE.INODE_ALTERATION
                        )
                        alter = 'FILE_INODE_ALTERATION'
                    end
                    if awhat == '1' and alter_lst ~= '' then
                        db_awatcher.upd(
                            wid, file, true, FILE.ANY_ALTERATION
                        )
                        print(prompt..'FILE_ANY_ALTERATION:' ..file)
                        not_alter_yet[i] = nil --Exclude item
                    else
                        if string_find(alter_lst, awhat) then
                            db_awatcher.upd(
                                wid, file, true, awhat
                            )
                            print(prompt..alter..':' ..file)
                            not_alter_yet[i] = nil --Exclude item
                        end
                    end
                end
                if db_awatcher.match(wid, awhat)>=nmatch then
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
    BULK_FILE_ALTERATION_END:signal()
end

--levels: {0, 1,2,3,4,5..}
local function recursive_tree(
    --[[required]] root,
    --[[optional]] levels,
    --[[optional]] shidden
)
    local _levels = levels or {0}          --zero for all directory levels
    local _shidden = shidden or false  --false for ignore the hidden files and folders

    table.sort(_levels) --Sort _levels

    local function get_level (path)
        local folders={}
        for str in string.gmatch(path, "([^/]+)") do
            --table.insert(folders, str)
            folders[#folders+1] = str
        end
        return #folders
    end

    local level_root = get_level(root) --root level ref

    local t = {} --table resultant

    local function explore_dir(dir)
        local level = get_level(dir) - level_root
        if (level > _levels[#_levels]) then
            return t
        end
        if fio_is_dir(dir) then
            local flst = fio_listdir(dir)
            if flst then
                for k=1,#flst do
                    local file = flst[k]
                    local ofile
                    if (string.byte(file, 1) ~= 46) or (_shidden == true) then
                        ofile = string.format('%s/%s', dir, file)
                        if (_levels[1]==0) or (ut.is_val_of(_levels, level)) then
                            t[#t+1] = ofile
                        end
                        if fio_is_dir(ofile) then
                            explore_dir(ofile)
                        end
                    end
                end
            end
            collectgarbage()
        end
    end

    explore_dir(root)

    return t
end

--- Consolidate the watch list items
-- Expand patterns types if exists and Remove duplicates for FW Deletion
local function consolidate(
    wlist,
    recursion,
    levels,
    hidden,
    ignored
)
    local _recursion = recursion or false
    local _levels = levels or {0}
    local _hidden = hidden or false
    local _ignored = ignored or {''}

    local _wlist = ut.deduplicate(wlist)

    local t = {}
    for _,v in pairs(_wlist) do
        if v ~= '' and not ut.is_val_of(_ignored, v) then
            if string_find(v, '*') then
                local pattern_result = fio_glob(v)
                --Merge pattern items result with t
                if #pattern_result~=0 then
                    for _,nv in ipairs(pattern_result) do
                        t[#t+1] = nv
                    end
                else
                    t[#t+1] = v
                end
            else
                if (_recursion==true) and fio_is_dir(v) then
                    local tr = recursive_tree(v, _levels, _hidden)
                    for rv = 1, #tr do
                        t[#t+1] = tr[rv]
                    end
                else
                    t[#t+1] = v
                end
            end
        end
    end

    if #t~=0 then
        return ut.deduplicate(t)
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

    local is_stable
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
    if not is_stable then is_stable = false end
    return is_stable, mssg
end

local BULK_FILE_CREATION_END = fiber.cond() --Bulk file creacion end

local function bulk_file_creation(
    wid,
    bulk,
    maxwait,
    interval,
    minsize,
    stability,
    novelty,
    nmatch
)

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
                        if not (lmod >= _novelty.minage and lmod <= _novelty.maxage) then
                            db_awatcher.upd(
                                wid, data, false, FILE.IS_NOT_NOVELTY
                            )
                            print(prompt..'FILE_IS_NOT_NOVELTY:' ..data)
                            return
                        end
                    end
                    if _stability then
                        local stble, merr = is_stable_size(
                            data,
                            _stability.frecuency, --[1], --frec
                            _stability.iterations --[2] --iterations
                        )
                        if not stble then
                            db_awatcher.upd(
                                wid, data, false, FILE.UNSTABLE_SIZE
                            )
                            print(prompt..'FILE_UNSTABLE_SIZE:' ..data)
                            if merr then
                                db_awatcher.upd(wid, data, false, merr)
                            end
                            return
                        end
                    end
                    if _minsize then
                        if not (fio_lstat(data).size >= minsize) then
                            db_awatcher.upd(wid, data, false, FILE.UNEXPECTED_SIZE)
                            print(prompt..'FILE_UNEXPECTED_SIZE:' ..data)
                            return
                        end
                    end
                    db_awatcher.upd(wid, data, true, FILE.HAS_BEEN_CREATED)
                    print(prompt..'FILE_HAS_BEEN_CREATED:' ..data)
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
                        db_awatcher.upd(
                            wid, v, true, FILE.HAS_BEEN_CREATED
                        )
                        print(prompt..'FILE_HAS_BEEN_CREATED:' ..v)
                    end
                end
            else
                local pit = fio_glob(v) --pattern_items
                if #pit~=0 then
                    for _,u in pairs(pit) do
                        if not ut.is_val_of(fnd, u) then
                            fnd[#fnd+1]=u
                            nfp = nfp + 1
                            if stability or minsize or novelty then
                                db_awatcher.add(wid, u)
                                ch_cff:put(u, 0)
                            else
                                db_awatcher.put(wid, u, true, FILE.HAS_BEEN_CREATED)
                                print(prompt..'FILE_HAS_BEEN_CREATED:' ..u)
                            end
                        end
                    end
                end
            end
        end
        --Exit as soon as posible
        local actual_match = db_awatcher.match(wid)
        if (nmatch==0 and actual_match > nmatch) or (nmatch~=0 and actual_match >= nmatch) then
            break
        end
        fib_sleep(interval)
    end
    --'MAXWAIT_TIMEOUT'
    BULK_FILE_CREATION_END:signal()
end

--File watcher deletion
local function file_deletion(
    wid,
    cwlist,
    maxwait,
    interval,
    sort,
    cases,
    match
)

    local nfiles = #cwlist
    local _cases = cases or 0
    local _match = match or 0
    local _sort = sort or SORT.NO_SORT

    if _cases==0 then _cases = nfiles end
    if _match==0 then _match = nfiles end

    local cwlist_o

    if #cwlist == 1 then
        cwlist_o = cwlist
    else
        cwlist_o = sort_files_by(cwlist, _sort, _cases)
    end

    local nbulks = math.floor(1 + (#cwlist_o)/BULK_CAPACITY)
    local bulk_fibs = {} --Fiber list
    local pos = 0

    for i = 1, nbulks do
        local bulk = {}
        local val
        for j = 1,BULK_CAPACITY,1 do
            pos = pos + 1
            val = cwlist_o[pos]
            if val then
                bulk[j] = val
                db_awatcher.add(wid, val, false, FILE.NOT_YET_DELETED)
            else
                break
            end
        end
        local bfid = fiber.create(
            bulk_file_deletion,
            wid,
            bulk,
            maxwait,
            interval,
            _match
        )
        bfid:name('fwd-bulk-d')
        bulk_fibs[i] = bfid
    end

    BULK_FILE_DELETION_END:wait()

    --Cancel fibers
    for _, fib in pairs(bulk_fibs) do
        local fid = fiber.id(fib)
        pcall(fiber.cancel, fid)
    end

    return {
        wid = wid,
        ans = db_awatcher.close(wid, match, WATCHER.FILE_DELETION)
    }

end

--- File Watch for File Creations
--
local function file_creation(
    --[[required]] wid,
    --[[required]] wlist,
    --[[optional]] maxwait,
    --[[optional]] interval,
    --[[optional]] minsize,
    --[[optional]] stability,
    --[[optional]] novelty,
    --[[optional]] match
)

    local nbulks = math.floor(1 + (#wlist)/BULK_CAPACITY)
    local bulk_fibs = {} --Fiber list
    local pos = 0

    for i = 1, nbulks do
        local bulk = {}
        local val
        for j = 1, BULK_CAPACITY do
            pos = pos + 1
            val = wlist[pos]
            if val then
                bulk[j] = val
                if not string_find(val, '*') then
                    db_awatcher.add(wid, val)
                --[[else
                    --TODO: Review this, it is necessary?
                    db_awatcher.add(
                        wid,
                        val,
                        false,
                        FILE.IS_PATTERN
                    )
                    ]]
                end
            else
                break
            end
        end
        local bfid = fiber.create(
            bulk_file_creation,
            wid,
            bulk,
            maxwait,
            interval,
            minsize,
            stability,
            novelty,
            match
        )
        bfid:name('fwc-bulk-c')
        bulk_fibs[i] = bfid
    end

    BULK_FILE_CREATION_END:wait()

    --Cancel fibers
    for _, fib in pairs(bulk_fibs) do
        local fid = fiber.id(fib)
        pcall(fiber.cancel, fid)
    end

    return {
        wid = wid,
        ans = db_awatcher.close(
            wid,
            match,
            WATCHER.FILE_CREATION
        )
    }

end

local function file_alteration(
    wid,
    wlist,
    maxwait,
    interval,
    awhat,
    match
)

    local fio_lstat = fio.lstat
    local dig_sha256 = dig.sha256
    local io_open = io.open
    local fio_exists = fio.path.lexists

    local nbulks = math.floor(1 + (#wlist)/BULK_CAPACITY)
    local bulk_fibs = {} --Fiber list
    local pos = 0

    for i = 1, nbulks do
        local bulk = {}
        local val
        local k = 0
        for _ = 1, BULK_CAPACITY do
            pos = pos + 1
            val = wlist[pos]
            local _sha256
            if val then
                if fio_exists(val) then
                    local flf = fio_lstat(val)
                    --FIX: When file dissapear this fail with  error
                    --     attempt to index local 'flf' (a nil value)
                    --     This occur when the file is erased or change extension
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
                    db_awatcher.add(wid, val, false, FILE.NO_ALTERATION)
                else
                    db_awatcher.put(wid, val, false, FILE.NOT_EXISTS) --0r dissapear?
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
                awhat,
                maxwait,
                interval,
                match
            )
            bfid:name('fwa-bulk-a')
            bulk_fibs[i] = bfid
        end
    end
    if bulk_fibs[1] then
        BULK_FILE_ALTERATION_END:wait() --Waiting for ended
        --Cancel fibers
        for _, fib in pairs(bulk_fibs) do
            local fid = fiber.id(fib)
            pcall(fiber.cancel, fid)
        end
    end

    return {
        wid = wid,
        ans = db_awatcher.close(wid, match, awhat)
    }

end

-- Export API functions
return {
    deletion = file_deletion,
    creation = file_creation,
    alteration = file_alteration,
    consolidate = consolidate,
    recursive = recursive_tree
}