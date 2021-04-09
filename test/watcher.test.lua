#!/usr/bin/env tarantool

package.path = package.path .. '../watcher/src/?.lua;../watcher/?.lua'

local strict = require("strict")
local fwt = require('watcher').file
local tap = require('tap')
local fiber = require('fiber')
local log = require('log')

strict.on()

local function remove_file(file, waitfor)
    fiber.sleep(waitfor)
    os.remove(file)
end

local function remove_tmp_files(waitfor)
    fiber.sleep(waitfor)
    os.execute('rm -rf /tmp/lua_*')
end

local function remove_tmp_folder(waitfor)
    fiber.sleep(waitfor)
    os.execute('rm -rf /tmp/thefolder')
end

local function create_file(file, waitfor)
    fiber.sleep(waitfor)
    os.execute('touch ' .. file)
end

local TEST = {
    FWD01 = '01. FW_PATH_ISEMPTY          -- Expected: Nothing for watch',
    FWD02 = "02. FW_FILE_NOT_EXISTS       -- Expected: The file don't exist",
    FWD03 = '03. FW_NOWAIT_MAXWAIT        -- Expected: No wait if file not exist',
    FWD04 = "04. FW_FOLDER_NOT_EXISTS     -- Expected: The path don't exist",
    FWD05 = '05. FW_FILE_NOT_DELETED      -- Expected: The file has not been deleted',
    FWD06 = '06. FW_FILE_NOT_DELETED      -- Expected: File not deleted in the maxwait interval',
    FWD07 = '07. FW_FILE_DELETED          -- Expected: The file has been deleted',
    FWD08 = '08. FW_NOTHING_DELETED       -- Expected: No file on the list has been removed',
    FWD09 = '09. FW_ALL_LIST_DELETED      -- Expected: All files have been deleted',
    FWD10 = '10. FW_MATCH_NOT_DELETED     -- Expected: Some items on the list have not been removed',
    FWD11 = '11. FW_MATCH_DELETED         -- Expected: The number of cases has been eliminated',
    FWD12 = '12. FW_NOTHING_DELETED_PF    -- Expected: No pattern elements have been removed',
    FWD13 = '13. FW_ALL_DELETED           -- Expected: All the pattern files have been deleted',
    FWD14 = '14. FW_DIR_DELETED           -- Expected: The folder has been deleted',
    FWD15 = '15. FW_ALL_DELETED_MIX       -- Expected: Combine lists and patterns together',
    FWD16 = '16. FW_MATCH_DELETED_FNO     -- Expected: Match first 2 from 3 fst items ordered by change alpha asc',
    FWD17 = '17. FW_MATCH_DELETED_FN1     -- Expected: Match first 2 from 3 fst items ordered by change alpha dsc',
    FWD18 = '18. FW_PATTERN_MATCH_FN2     -- Expected: Match first 2 from 3 fst items ordered by change mtime asc',
    FWD19 = '19. FW_PATTERN_MATCH_FN3     -- Expected: Match first 2 from 3 fst items ordered by change mtime dsc',
    FWD20 = '20. FW_PATTERN_MATCH_FN4     -- Expected: Match first 2 from 3 fst items ordered by change mtime dsc',
    FWD21 = '21. FW_FILE_ALREADY_EXISTED  -- Expected: The file already existed',
    FWD22 = '22. FW_FILE_HAS_ARRIVED      -- Expected: The file has arrived!',
    FWD23 = '23. FW_FILE_NOT_ARRIVED      -- Expected: The file has not been created'
}

log.info('Initiating Watcher testing using TAP')

local test = tap.test('test-file-watcher')
test:plan(5)
local pini = os.time()
test:test('Single File Deletion -> File does not exist', function(t)
    t:plan(4)

    --FWD01
    local res = pcall(fwt.deletion, {''})
    t:is(res, false, TEST.FWD01)

    --FWD02
    local file_not_exist_yet = '_THIS.NOT$_?EXIST%'
    local res = fwt.deletion({file_not_exist_yet})
    t:is(res.ans, true, TEST.FWD02)
    
    --FWD03
    local MAXWAIT = 5
    local tini = os.time()
    local _ = fwt.deletion({'/tmp/' .. file_not_exist_yet}, MAXWAIT)
    local elapsed_time = os.difftime(os.time() - tini)
    t:ok(elapsed_time < MAXWAIT, TEST.FWD03)

    --FWD04
    local folder_not_exist_yet = '/tmp/THIS_FOLDER_NOT_EXIST/'
    local res = fwt.deletion({folder_not_exist_yet})
    t:is(res.ans, true, TEST.FWD04)
end)

test:test('Single File Deletion -> File exists but is not deleted', function(t)
    t:plan(2)

    --FWD05
    local MAXWAIT = 10
    local this_file_exist = os.tmpname()
    local res = fwt.deletion({this_file_exist}, MAXWAIT)
    t:is(res.ans, false, TEST.FWD05)

    --FWD06
    MAXWAIT = 5
    fiber.create(remove_file, this_file_exist, 10)
    local res = fwt.deletion({this_file_exist}, MAXWAIT)
    t:is(res.ans, false, TEST.FWD06)
end)

test:test('Single File Deletion -> File exists and is deleted', function(t)
    t:plan(1)

    --FWD07
    local MAXWAIT = 8
    local this_file_exist = os.tmpname()
    fiber.create(remove_file, this_file_exist, 5)
    local res = fwt.deletion({this_file_exist}, MAXWAIT)
    t:is(res.ans, true, TEST.FWD07)
end)

test:test('Multiple File Deletion -> Some varied experiments', function(t)
    t:plan(13)

    --FWD08
    local MAXWAIT = 3
    local INTERVAL = 0.5
    local f1 = os.tmpname()
    local f2 = os.tmpname()
    local f3 = os.tmpname()
    local file_list = {f1, f2, f3}
    local res = fwt.deletion(file_list, MAXWAIT, INTERVAL)
    t:is(res.ans, false, TEST.FWD08)

    --FWD09
    MAXWAIT = 10
    fiber.create(remove_file, f1, 1.5)
    fiber.create(remove_file, f2, 1.5)
    fiber.create(remove_file, f3, 1.5)
    local res = fwt.deletion(file_list, MAXWAIT, INTERVAL, {nil, nil, 3})
    t:is(res.ans, true, TEST.FWD09)

    --FWD10
    local f4 = os.tmpname()
    local f5 = os.tmpname()
    local f6 = os.tmpname()
    local f7 = os.tmpname()
    local f8 = os.tmpname()
    local f9 = os.tmpname()
    local file_list_2 = {f4, f5, f6, f7, f8, f9}
    fiber.create(remove_file, f4, 1)
    fiber.create(remove_file, f5, 3)
    local res = fwt.deletion(file_list_2, MAXWAIT, INTERVAL)
    t:is(res.ans, false, TEST.FWD10)

    --FWD11
    MAXWAIT = 10
    local file_list_3 = {f6, f7, f8, f9}
    fiber.create(remove_file, f6, 1)
    fiber.create(remove_file, f7, 1)
    fiber.create(remove_file, f9, 1)
    local res = fwt.deletion(file_list_3, MAXWAIT, INTERVAL, {nil, nil, 3})
    t:is(res.ans, true, TEST.FWD11)

    --FWD12
    for _=1,10 do os.tmpname() end
    local file_pattern = {'/tmp/*'}
    local res = fwt.deletion(file_pattern, MAXWAIT, INTERVAL)
    t:is(res.ans, false, TEST.FWD12)

    --FWD13
    MAXWAIT = 15
    os.execute('touch /tmp/FAD_aaaaa')
    os.execute('touch /tmp/FAD_abaaa')
    os.execute('touch /tmp/FAD_acaaa')
    os.execute('touch /tmp/FAD_adaaa')
    fiber.create(remove_file, '/tmp/FAD_aaaaa', 2)
    fiber.create(remove_file, '/tmp/FAD_abaaa', 2)
    fiber.create(remove_file, '/tmp/FAD_acaaa', 2)
    fiber.create(remove_file, '/tmp/FAD_adaaa', 2)
    local res = fwt.deletion({'/tmp/FAD_*'}, MAXWAIT, INTERVAL)
    t:is(res.ans, true, TEST.FWD13)

    --FWD14
    local folder = {'/tmp/thefolder'}
    os.execute('mkdir /tmp/thefolder')
    os.execute('touch /tmp/thefolder/tst1.txt')
    os.execute('touch /tmp/thefolder/tst2.txt')
    os.execute('touch /tmp/thefolder/tst3.txt')
    fiber.create(remove_tmp_folder, 3)
    local res = fwt.deletion(folder, MAXWAIT, INTERVAL)
    t:is(res.ans, true, TEST.FWD14)

    --FWD15
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
    local res = fwt.deletion(watcher_mix, MAXWAIT, INTERVAL)
    t:is(res.ans, true, TEST.FWD15)

    --FWD16
    os.execute('touch /tmp/f_G.txt')
    os.execute('touch /tmp/f_H.txt')
    os.execute('touch /tmp/f_I.txt')
    os.execute('touch /tmp/f_J.txt')
    os.execute('touch /tmp/f_K.txt')
    os.execute('touch /tmp/f_L.txt')
    local n_match = 2
    fiber.create(remove_file, '/tmp/f_G.txt', 2)
    fiber.create(remove_file, '/tmp/f_L.txt', 2)
    fiber.create(remove_file, '/tmp/f_K.txt', 2)
    local res = fwt.deletion({'/tmp/f_*'}, MAXWAIT, INTERVAL, {'AA', 3, n_match})
    t:is(res.ans, false, TEST.FWD16)

    --FWD17
    remove_pattrn('/tmp/f_*', 0)
    os.execute('touch /tmp/f_G.txt')
    os.execute('touch /tmp/f_H.txt')
    os.execute('touch /tmp/f_I.txt')
    os.execute('touch /tmp/f_J.txt')
    os.execute('touch /tmp/f_K.txt')
    os.execute('touch /tmp/f_L.txt')
    local n_match = 2
    fiber.create(remove_file, '/tmp/f_G.txt', 2)
    fiber.create(remove_file, '/tmp/f_L.txt', 2)
    fiber.create(remove_file, '/tmp/f_K.txt', 2)
    local res = fwt.deletion({'/tmp/f_*'}, MAXWAIT, INTERVAL, {'AD', 3, n_match})
    t:is(res.ans, true, TEST.FWD17)

    --FWD18
    remove_pattrn('/tmp/f_*', 0)
    os.execute('touch /tmp/f_1.txt')
    fiber.sleep(1)
    os.execute('touch /tmp/f_2.txt')
    fiber.sleep(1)
    os.execute('touch /tmp/f_3.txt')
    fiber.sleep(1)
    os.execute('touch /tmp/f_4.txt')
    local n_match = 2
    fiber.create(remove_file, '/tmp/f_1.txt', 2)
    fiber.create(remove_file, '/tmp/f_3.txt', 2)
    local res = fwt.deletion({'/tmp/f_*'}, MAXWAIT, INTERVAL, {'MA', 3, n_match})
    t:is(res.ans, true, TEST.FWD18)

    --FWD19
    remove_pattrn('/tmp/f_*', 0)
    os.execute('touch /tmp/f_1.txt')
    os.execute('touch /tmp/f_2.txt')
    os.execute('touch /tmp/f_3.txt')
    os.execute('touch /tmp/f_4.txt')
    local n_match = 2
    fiber.create(remove_file, '/tmp/f_1.txt', 2)
    fiber.create(remove_file, '/tmp/f_3.txt', 2)
    local res = fwt.deletion({'/tmp/f_*'}, MAXWAIT, INTERVAL, {'MD', 3, n_match})
    t:is(res.ans, false, TEST.FWD19)

    --FWD20
    remove_pattrn('/tmp/f_*', 0)
    os.execute('touch /tmp/f_1.txt')
    os.execute('touch /tmp/f_2.txt')
    os.execute('touch /tmp/f_3.txt')
    os.execute('touch /tmp/f_4.txt')
    local n_match = 2
    fiber.create(remove_file, '/tmp/f_2.txt', 2)
    fiber.create(remove_file, '/tmp/f_3.txt', 2)
    local res = fwt.deletion({'/tmp/f_*'}, MAXWAIT, INTERVAL, {'MD', 3, n_match})
    t:is(res.ans, true, TEST.FWD20)

    --test:is(#obj, n_match, TEST.FWD18)

end)

test:test('Single File Creation', function(t)
    t:plan(3)

    local MAXWAIT = 4
    local INTERVAL = 0.5 

    --FWD21
    local c1 = os.tmpname()
    fiber.sleep(2)
    local res = fwt.creation({c1}, MAXWAIT, INTERVAL)
    t:is(res.ans, true, TEST.FWD21)

    --FWD22
    create_file('/tmp/c_fdw022', 3)
    local res = fwt.creation({c1}, MAXWAIT, INTERVAL)
    t:is(res.ans, true, TEST.FWD22)

    --FWD23
    local res = fwt.creation({'/tmp/c_fdw023'}, MAXWAIT, INTERVAL)
    t:is(res.ans, false, TEST.FWD23)

end)

print('Elapsed time: ' .. os.difftime(os.time() - pini) .. 's')

log.info('Finishing the tests')

os.exit(test:check() == true and 0 or -1)

return {
    test = test
}