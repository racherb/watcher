#!/usr/bin/env tarantool

local strict = require("strict")
local fwt = require('watcher').file
local tap = require('tap')
local fiber = require('fiber')

strict.on()

local function remove_file(file, waitfor)
    fiber.sleep(waitfor)
    os.remove(file)
end

local function remove_tmp_files(waitfor)
    fiber.sleep(waitfor)
    os.execute('rm -rf /tmp/*')
end

local TEST = {
    FW_PATH_ISEMPTY         = '01. FW_PATH_ISEMPTY          - Nothing for watch',
    FW_FILE_NOT_EXISTS      = "02. FW_FILE_NOT_EXISTS       - The file don't exist",
    NO_WAIT_MAXWAIT         = '03. NO WAIT MAXWAIT          - No wait if file not exist',
    FW_FOLDER_NOT_EXISTS    = "04. FW_FOLDER_NOT_EXISTS     - The path don't exist",
    FW_FILE_NOT_DELETED     = '05. FW_FILE_NOT_DELETED      - The file has not been deleted',
    FW_FILE_NOT_DELETED_MW  = '06. FW_FILE_NOT_DELETED      - File not deleted in the maxwait interval',
    FW_FILE_DELETED         = '07. FW_FILE_DELETED          - The file has been deleted',
    FW_NOTHING_DELETED      = '08. FW_NOTHING_DELETED       - No file on the list has been removed',
    FW_ALL_LIST_DELETED     = '09. FW_ALL_LIST_DELETED      - All files have been deleted',
    FW_MATCH_NOT_DELETED    = '10. FW_MATCH_NOT_DELETED     - Some items on the list have not been removed',
    FW_MATCH_DELETED        = '11. FW_MATCH_DELETED         - The number of cases has been eliminated',
    FW_NOTHING_DELETED_PF   = '12. FW_NOTHING_DELETED_PF    - No pattern elements have been removed',
    FW_ALL_DELETED          = '13. FW_ALL_DELETED           - All the pattern files have been deleted',
    FW_DIR_DELETED          = '14. FW_DIR_DELETED           - The folder has been deleted',
    FW_ALL_DELETED_MIX      = '15. FW_ALL_DELETED_MIX       - Combine lists and patterns together',
    FW_MATCH_DELETED_FNO    = '16. FW_MATCH_DELETED_FNO     - Match first N items ordered by change date asc',
    FW_MATCH_DELETED_FMI    = '17. FW_MATCH_DELETED_FMI     - Return of the first match N items'
}

local test = tap.test('test-file-watcher')
test:plan(4)
local pini = os.time()
test:test('single_file_deletion:file_not_exist', function(t)
    t:plan(4)
    local ans = pcall(fwt.deletion, {''})
    t:is(ans, false, TEST.FW_PATH_ISEMPTY)

    local file_not_exist_yet = '_THIS.NOT$_?EXIST%'
    ans = fwt.deletion({file_not_exist_yet})
    t:is(ans, true, TEST.FW_FILE_NOT_EXISTS)

    local MAXWAIT = 5
    local tini = os.time()
    local _ = fwt.deletion({'/tmp/' .. file_not_exist_yet}, MAXWAIT)
    local elapsed_time = os.difftime(os.time() - tini)
    t:ok(elapsed_time < MAXWAIT, TEST.NO_WAIT_MAXWAIT)
    local folder_not_exist_yet = '/tmp/THIS_FOLDER_NOT_EXIST/'
    ans = fwt.deletion({folder_not_exist_yet})
    t:is(ans, true, TEST.FW_FOLDER_NOT_EXISTS)
end)

test:test('single_file_deletion:file_exist_not_deleted', function(t)
    t:plan(2)
    local MAXWAIT = 10
    local this_file_exist = os.tmpname()
    local ans = fwt.deletion({this_file_exist}, MAXWAIT)
    t:is(ans, false, TEST.FW_FILE_NOT_DELETED)

    MAXWAIT = 5
    fiber.create(remove_file, this_file_exist, 10)
    ans = fwt.deletion({this_file_exist}, MAXWAIT)
    t:is(ans, false, TEST.FW_FILE_NOT_DELETED_MW)
end)

test:test('single_file_deletion:file_exist_deleted', function(t)
    t:plan(1)
    local MAXWAIT = 8
    local this_file_exist = os.tmpname()
    fiber.create(remove_file, this_file_exist, 5)
    local ans = fwt.deletion({this_file_exist}, MAXWAIT)
    t:is(ans, true, TEST.FW_FILE_DELETED)
end)

test:test('multiple_file_deletion:list_experiments', function(t)
    t:plan(10)
    local MAXWAIT = 3
    local INTERVAL = 0.5
    local f1 = os.tmpname()
    local f2 = os.tmpname()
    local f3 = os.tmpname()
    local file_list = {f1, f2, f3}
    local ans = fwt.deletion(file_list, MAXWAIT, INTERVAL)
    t:is(ans, false, TEST.FW_NOTHING_DELETED)

    MAXWAIT = 10
    fiber.create(remove_file, f1, 1.5)
    fiber.create(remove_file, f2, 1.5)
    fiber.create(remove_file, f3, 1.5)
    ans = fwt.deletion(file_list, MAXWAIT, INTERVAL, {nil, nil, 3})
    t:is(ans, true, TEST.FW_ALL_LIST_DELETED)

    local f4 = os.tmpname()
    local f5 = os.tmpname()
    local f6 = os.tmpname()
    local f7 = os.tmpname()
    local f8 = os.tmpname()
    local f9 = os.tmpname()
    local file_list_2 = {f4, f5, f6, f7, f8, f9}
    fiber.create(remove_file, f4, 1)
    fiber.create(remove_file, f5, 3)
    ans = fwt.deletion(file_list_2, MAXWAIT, INTERVAL)
    t:is(ans, false, TEST.FW_MATCH_NOT_DELETED)

    MAXWAIT = 10
    local file_list_3 = {f6, f7, f8, f9}
    fiber.create(remove_file, f6, 1)
    fiber.create(remove_file, f7, 1)
    fiber.create(remove_file, f9, 1)
    ans = fwt.deletion(file_list_3, MAXWAIT, INTERVAL, {nil, nil, 3})
    t:is(ans, true, TEST.FW_MATCH_DELETED)

    for _=1,10 do os.tmpname() end
    local file_pattern = {'/tmp/*'}
    ans = fwt.deletion(file_pattern, MAXWAIT, INTERVAL)
    t:is(ans, false, TEST.FW_NOTHING_DELETED_PF)

    MAXWAIT = 15
    os.execute('touch /tmp/FAD_aaaaa')
    os.execute('touch /tmp/FAD_abaaa')
    os.execute('touch /tmp/FAD_acaaa')
    os.execute('touch /tmp/FAD_adaaa')
    fiber.create(remove_file, '/tmp/FAD_aaaaa', 2)
    fiber.create(remove_file, '/tmp/FAD_abaaa', 2)
    fiber.create(remove_file, '/tmp/FAD_acaaa', 2)
    fiber.create(remove_file, '/tmp/FAD_adaaa', 2)
    ans = fwt.deletion({'/tmp/FAD_*'}, MAXWAIT, INTERVAL)
    t:is(ans, true, TEST.FW_ALL_DELETED)

    local folder = {'/tmp/thefolder'}
    os.execute('mkdir /tmp/thefolder')
    os.execute('touch /tmp/thefolder/tst1.txt')
    os.execute('touch /tmp/thefolder/tst2.txt')
    os.execute('touch /tmp/thefolder/tst3.txt')
    fiber.create(remove_tmp_files, 3)
    ans = fwt.deletion(folder, MAXWAIT, INTERVAL)
    t:is(ans, true, TEST.FW_DIR_DELETED)

    os.execute('touch /tmp/tst1.txt')
    os.execute('touch /tmp/tst2.txt')
    os.execute('touch /tmp/tst3.txt')
    os.execute('touch /tmp/tst4.txt')
    os.execute('touch /tmp/tst5.abc')
    os.execute('touch /tmp/tst6.abc')
    local watcher_mix = {'/tmp/tst*.txt', '/tmp/tst6.abc'}
    local function remove_pattrn(pattrn, waitfor)
        fiber.sleep(waitfor)
        os.execute('rm -rf ' .. pattrn)
    end
    fiber.create(remove_pattrn, '/tmp/tst*.txt', 3)
    fiber.create(remove_file, '/tmp/tst6.abc', 1)
    ans = fwt.deletion(watcher_mix, MAXWAIT, INTERVAL)
    t:is(ans, true, TEST.FW_ALL_DELETED_MIX)

    MAXWAIT = 7
    INTERVAL = 0.5
    os.execute('touch /tmp/f_a.txt')
    os.execute('touch /tmp/f_b.txt')
    os.execute('touch /tmp/f_c.txt')
    os.execute('touch /tmp/f_d.txt')
    os.execute('touch /tmp/f_e.txt')
    os.execute('touch /tmp/f_f.txt')
    fiber.create(remove_file, '/tmp/f_b.txt', 2)
    fiber.create(remove_file, '/tmp/f_c.txt', 2)
    local n_match = 2
    local options = {'MTIME_ASC', 3, n_match}
    ans = fwt.deletion({'/tmp/f_*'}, MAXWAIT, INTERVAL, options)
    t:is(ans, true, TEST.FW_MATCH_DELETED_FNO)
    --test:is(#obj, n_match, TEST.FW_MATCH_DELETED_FMI)

end)

print('Elapsed time: ' .. os.difftime(os.time() - pini) .. 's')

os.exit(test:check() == true and 0 or -1)

return {
    test = test
}