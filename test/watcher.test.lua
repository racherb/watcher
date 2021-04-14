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

local function append_file(file, waitfor)
    fiber.sleep(waitfor)
    local command = 'echo "*UYHBVCDCV" >> ' ..file
    os.execute(command)
end

local function create_nfiles(n)
    for _=1, n do
        os.tmpname()
    end
end

log.info('Initiating Watcher testing using TAP')

local test = tap.test('test-file-watcher')
test:plan(6)

local res
local n_match
local pini = os.time()

--Plan 1
test:test('Single File Deletion -> File does not exist', function(t)

    local TEST = {
        FWD01 = 'Nothing for watch',
        FWD02 = "The file don't exist",
        FWD03 = 'No wait if file not exist',
        FWD04 = "The path don't exist"
    }

    t:plan(4)

    --FWD01
    res = pcall(fwt.deletion, {''})
    t:is(res, false, TEST.FWD01)

    --FWD02
    local file_not_exist_yet = '_THIS.NOT$_?EXIST%'
    res = fwt.deletion({file_not_exist_yet})
    t:is(res.ans, true, TEST.FWD02)

    --FWD03
    local MAXWAIT = 5
    local tini = os.time()
    local _ = fwt.deletion({'/tmp/' .. file_not_exist_yet}, MAXWAIT)
    local elapsed_time = os.difftime(os.time() - tini)
    t:ok(elapsed_time < MAXWAIT, TEST.FWD03)

    --FWD04
    local folder_not_exist_yet = '/tmp/THIS_FOLDER_NOT_EXIST/'
    res = fwt.deletion({folder_not_exist_yet})
    t:is(res.ans, true, TEST.FWD04)
end)

--Plan 2
test:test('Single File Deletion -> File exists but is not deleted', function(t)

    local TEST = {
        FWD01 = 'The file has not been deleted',
        FWD02 = 'File not deleted in the maxwait interval'
    }

    t:plan(2)

    --FWD05
    local MAXWAIT = 10
    local this_file_exist = os.tmpname()
    res = fwt.deletion({this_file_exist}, MAXWAIT)
    t:is(res.ans, false, TEST.FWD01)

    --FWD06
    MAXWAIT = 5
    fiber.create(remove_file, this_file_exist, 10)
    res = fwt.deletion({this_file_exist}, MAXWAIT)
    t:is(res.ans, false, TEST.FWD02)
end)

--Plan 3
test:test('Single File Deletion -> File exists and is deleted', function(t)

    local TEST = {
        FWD01 = 'The file has been deleted'
    }

    t:plan(1)

    --FWD07
    local MAXWAIT = 8
    local this_file_exist = os.tmpname()
    fiber.create(remove_file, this_file_exist, 5)
    res = fwt.deletion({this_file_exist}, MAXWAIT)
    t:is(res.ans, true, TEST.FWD01)
end)

--Plan 4
test:test('Multiple File Deletion -> Some varied experiments', function(t)

    local TEST = {
        FWD01 = 'No file on the list has been removed',
        FWD02 = 'All files have been deleted',
        FWD03 = 'Some items on the list have not been removed',
        FWD04 = 'The number of cases has been eliminated',
        FWD05 = 'No pattern elements have been removed',
        FWD06 = 'All the pattern files have been deleted',
        FWD07 = 'The folder has been deleted',
        FWD08 = 'Combine lists and patterns together',
        FWD09 = 'Match first 2 from 3 fst items ordered by change alpha asc',
        FWD10 = 'Match first 2 from 3 fst items ordered by change alpha dsc',
        FWD11 = 'Match first 2 from 3 fst items ordered by change mtime asc',
        FWD12 = 'Match first 2 from 3 fst items ordered by change mtime dsc',
        FWD13 = 'Match first 2 from 3 fst items ordered by change mtime dsc'
    }

    t:plan(13)

    --FWD08
    local MAXWAIT = 3
    local INTERVAL = 0.5
    local f1 = os.tmpname()
    local f2 = os.tmpname()
    local f3 = os.tmpname()
    local file_list = {f1, f2, f3}
    local res_g = fwt.deletion(file_list, MAXWAIT, INTERVAL)
    t:is(res_g.ans, false, TEST.FWD01)

    --FWD09
    MAXWAIT = 10
    fiber.create(remove_file, f1, 1.5)
    fiber.create(remove_file, f2, 1.5)
    fiber.create(remove_file, f3, 1.5)
    local res_h = fwt.deletion(file_list, MAXWAIT, INTERVAL, {nil, nil, 3})
    t:is(res_h.ans, true, TEST.FWD02)

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
    local res_i = fwt.deletion(file_list_2, MAXWAIT, INTERVAL)
    t:is(res_i.ans, false, TEST.FWD03)

    --FWD11
    MAXWAIT = 10
    local file_list_3 = {f6, f7, f8, f9}
    fiber.create(remove_file, f6, 1)
    fiber.create(remove_file, f7, 1)
    fiber.create(remove_file, f9, 1)
    local res_j = fwt.deletion(file_list_3, MAXWAIT, INTERVAL, {nil, nil, 3})
    t:is(res_j.ans, true, TEST.FWD04)

    --FWD12
    for _=1,10 do os.tmpname() end
    local file_pattern = {'/tmp/*'}
    local res_k = fwt.deletion(file_pattern, MAXWAIT, INTERVAL)
    t:is(res_k.ans, false, TEST.FWD05)

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
    res = fwt.deletion({'/tmp/FAD_*'}, MAXWAIT, INTERVAL)
    t:is(res.ans, true, TEST.FWD06)

    --FWD14
    local folder = {'/tmp/thefolder'}
    os.execute('mkdir /tmp/thefolder')
    os.execute('touch /tmp/thefolder/tst1.txt')
    os.execute('touch /tmp/thefolder/tst2.txt')
    os.execute('touch /tmp/thefolder/tst3.txt')
    fiber.create(remove_tmp_folder, 3)
    res = fwt.deletion(folder, MAXWAIT, INTERVAL)
    t:is(res.ans, true, TEST.FWD07)

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
    res = fwt.deletion(watcher_mix, MAXWAIT, INTERVAL)
    t:is(res.ans, true, TEST.FWD08)

    --FWD16
    os.execute('touch /tmp/f_G.txt')
    os.execute('touch /tmp/f_H.txt')
    os.execute('touch /tmp/f_I.txt')
    os.execute('touch /tmp/f_J.txt')
    os.execute('touch /tmp/f_K.txt')
    os.execute('touch /tmp/f_L.txt')

    n_match = 2

    fiber.create(remove_file, '/tmp/f_G.txt', 2)
    fiber.create(remove_file, '/tmp/f_L.txt', 2)
    fiber.create(remove_file, '/tmp/f_K.txt', 2)
    res = fwt.deletion({'/tmp/f_*'}, MAXWAIT, INTERVAL, {'AA', 3, n_match})
    t:is(res.ans, false, TEST.FWD09)

    --FWD17
    remove_pattrn('/tmp/f_*', 0)
    os.execute('touch /tmp/f_G.txt')
    os.execute('touch /tmp/f_H.txt')
    os.execute('touch /tmp/f_I.txt')
    os.execute('touch /tmp/f_J.txt')
    os.execute('touch /tmp/f_K.txt')
    os.execute('touch /tmp/f_L.txt')

    fiber.create(remove_file, '/tmp/f_G.txt', 2)
    fiber.create(remove_file, '/tmp/f_L.txt', 2)
    fiber.create(remove_file, '/tmp/f_K.txt', 2)
    res = fwt.deletion({'/tmp/f_*'}, MAXWAIT, INTERVAL, {'AD', 3, n_match})
    t:is(res.ans, true, TEST.FWD10)

    --FWD18
    remove_pattrn('/tmp/f_*', 0)
    os.execute('touch /tmp/f_1.txt')
    fiber.sleep(1)
    os.execute('touch /tmp/f_2.txt')
    fiber.sleep(1)
    os.execute('touch /tmp/f_3.txt')
    fiber.sleep(1)
    os.execute('touch /tmp/f_4.txt')

    fiber.create(remove_file, '/tmp/f_1.txt', 2)
    fiber.create(remove_file, '/tmp/f_3.txt', 2)
    res = fwt.deletion({'/tmp/f_*'}, MAXWAIT, INTERVAL, {'MA', 3, n_match})
    t:is(res.ans, true, TEST.FWD11)

    --FWD19
    remove_pattrn('/tmp/f_*', 0)
    os.execute('touch /tmp/f_1.txt')
    os.execute('touch /tmp/f_2.txt')
    os.execute('touch /tmp/f_3.txt')
    os.execute('touch /tmp/f_4.txt')

    fiber.create(remove_file, '/tmp/f_1.txt', 2)
    fiber.create(remove_file, '/tmp/f_3.txt', 2)
    res = fwt.deletion({'/tmp/f_*'}, MAXWAIT, INTERVAL, {'MD', 3, n_match})
    t:is(res.ans, false, TEST.FWD12)

    --FWD20
    remove_pattrn('/tmp/f_*', 0)
    os.execute('touch /tmp/f_1.txt')
    os.execute('touch /tmp/f_2.txt')
    os.execute('touch /tmp/f_3.txt')
    os.execute('touch /tmp/f_4.txt')

    fiber.create(remove_file, '/tmp/f_2.txt', 2)
    fiber.create(remove_file, '/tmp/f_3.txt', 2)
    res = fwt.deletion({'/tmp/f_*'}, MAXWAIT, INTERVAL, {'MD', 3, n_match})
    t:is(res.ans, true, TEST.FWD13)

    --test:is(#obj, n_match, TEST.FWD18)

end)

--Plan 5
test:test('Single File Creation', function(t)

    local TEST = {
        FWD01 = 'The file already existed',
        FWD02 = 'The file has arrived!',
        FWD03 = 'The file has not been created'
    }

    t:plan(3)

    local MAXWAIT = 4
    local INTERVAL = 0.5

    --FWD21
    local c1 = os.tmpname()
    fiber.sleep(2)
    res = fwt.creation({c1}, MAXWAIT, INTERVAL)
    t:is(res.ans, true, TEST.FWD01)

    --FWD22
    create_file('/tmp/c_fdw022', 3)
    res = fwt.creation({c1}, MAXWAIT, INTERVAL)
    t:is(res.ans, true, TEST.FWD02)

    --FWD23
    res = fwt.creation({'/tmp/c_fdw023'}, MAXWAIT, INTERVAL)
    t:is(res.ans, false, TEST.FWD03)

end)

--Plan 6
test:test('Advanced File Creation', function(t)

    local TEST = {
        FWD01 = 'The file size not expected',
        FWD02 = 'The file size has arrived!',
        FWD03 = '2000 files are expected and 2000 files arrive',
        FWD04 = '2100 files are expected but only 2000 arrive',
        FWD05 = 'The file has unexpectedly disappeared'
    }

    t:plan(5)

    local MAXWAIT = 4
    local INTERVAL = 0.5

    local c1 = os.tmpname()
    fiber.sleep(2)
    res = fwt.creation({c1}, MAXWAIT, INTERVAL, 10)
    t:is(res.ans, false, TEST.FWD01)

    append_file(c1, 2)
    res = fwt.creation({c1}, MAXWAIT, INTERVAL, 10)
    t:is(res.ans, true, TEST.FWD02)

    --fiber.create(append_file, c1, 2)

    remove_tmp_files(0)
    fiber.create(create_nfiles, 2000)
    res = fwt.creation({'/tmp/lua_*'}, nil, nil, 0, nil, nil, 2000)
    t:is(res.ans, true, TEST.FWD03)

    remove_tmp_files(0)
    fiber.create(create_nfiles, 2000)
    res = fwt.creation({'/tmp/lua_*'}, 10, nil, 0, nil, nil, 2100)
    t:is(res.ans, false, TEST.FWD04)
    remove_tmp_files(0)

    local c2 = os.tmpname()
    fiber.create(remove_file, c2, 5)
    res = fwt.creation({c2}, 10, INTERVAL, 10)
    t:is(res.ans, false, TEST.FWD05)

end)

print('Elapsed time: ' .. os.difftime(os.time() - pini) .. 's')

log.info('Finishing the tests')

os.exit(test:check() == true and 0 or -1)

return {
    test = test
}