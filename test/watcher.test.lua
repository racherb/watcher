#!/usr/bin/env tarantool

package.path = package.path .. ';../watcher/src/?.lua;../src/?.lua;?.lua;../test/?.lua;test/?.lua'

local tap = require('tap')
local fiber = require('fiber')
local helper = require('helper')

local fwt = require('watcher').file
local mon = require('watcher').monit
local core = require('watcher').core

local wat, res, prop, n_match, etime

local MAXWAIT
local INTERVAL

local pini = os.time()
test = tap.test('test-file-watcher')
test:plan(6)

--Plan 1
test:test('Single File Deletion >> The File Does Not Exist', function(t)

    t:plan(4)

    --FWD01
    wat = pcall(fwt.deletion, {''})
    t:is(wat, false, 'Nothing for watch')

    --FWD02
    local file_not_exist_yet = '_THIS.NOT$_?EXIST%'
    wat = fwt.deletion({file_not_exist_yet}).wid
    fiber.sleep(1)
    res = mon.info(wat).ans
    t:is(res, true, "The file don't exist")

    --FWD03
    MAXWAIT = 7
    local tini = os.time()
    local _ = core.waitfor(
        fwt.deletion({'/tmp/' .. file_not_exist_yet}, MAXWAIT
    ).wid)
    etime = os.difftime(os.time() - tini)
    t:ok(etime < MAXWAIT, 'No wait if file not exist')

    --FWD04
    local folder_not_exist_yet = '/tmp/THIS_FOLDER_NOT_EXIST/'
    wat = fwt.deletion({folder_not_exist_yet}).wid
    fiber.sleep(1)
    res = mon.info(wat).ans
    t:is(res, true, "The path don't exist")
end)

--Plan 2
test:test('Single File Deletion >> File Exists But Is Not Deleted', function(t)
    t:plan(2)

    --FWD05
    MAXWAIT = 5
    local this_file_exist = os.tmpname()
    wat = fwt.deletion({this_file_exist}, MAXWAIT).wid
    fiber.sleep(MAXWAIT+1)
    res = mon.info(wat).ans
    t:is(res, false, 'The file has not been deleted')

    --FWD06
    MAXWAIT = 3
    local this_file_exist_too = os.tmpname()
    wat = fwt.deletion({this_file_exist_too}, MAXWAIT).wid
    fiber.create(helper.remove_file, this_file_exist_too, MAXWAIT + 2)
    fiber.sleep(MAXWAIT + 2)
    res = mon.info(wat).ans
    t:is(res, false, 'File not deleted in the maxwait interval')
end)

--Plan 3
test:test('Single File Deletion >> File Exists And Is Deleted', function(t)
    t:plan(1)

    --FWD07
    MAXWAIT = 5
    local this_file_exist = os.tmpname()
    fiber.create(helper.remove_file, this_file_exist, 3)
    wat = fwt.deletion({this_file_exist}, MAXWAIT).wid
    fiber.sleep(4)
    res = mon.info(wat).ans
    t:is(res, true, 'The file has been deleted')
end)

--Plan 4
test:test('Multiple File Deletion >> Some varied experiments', function(t)

    t:plan(13)

    --FWD08
    MAXWAIT = 3
    INTERVAL = 0.5
    local f1 = os.tmpname()
    local f2 = os.tmpname()
    local f3 = os.tmpname()
    local file_list = {f1, f2, f3}
    wat = fwt.deletion(file_list, MAXWAIT, INTERVAL)
    fiber.sleep(MAXWAIT+1)
    res = mon.info(wat.wid)
    prop = (not res.ans) and (res.nomatch == #file_list)
    t:is(prop, true, 'No file on the list has been removed')

    --FWD09
    MAXWAIT = 5
    fiber.create(helper.remove_file, f1, 1.5)
    fiber.create(helper.remove_file, f2, 1.5)
    fiber.create(helper.remove_file, f3, 1.5)
    wat = fwt.deletion(file_list, MAXWAIT, INTERVAL, {nil, nil, 3})
    fiber.sleep(3*1.5 + 1)
    res = mon.info(wat.wid)
    t:is(res.ans, true, 'All files have been deleted')

    --FWD10
    local f4 = os.tmpname()
    local f5 = os.tmpname()
    local f6 = os.tmpname()
    local f7 = os.tmpname()
    local f8 = os.tmpname()
    local f9 = os.tmpname()
    local file_list_2 = {f4, f5, f6, f7, f8, f9}
    wat = fwt.deletion(file_list_2, MAXWAIT, INTERVAL)
    fiber.create(helper.remove_file, f4, 1)
    fiber.create(helper.remove_file, f5, 1)
    fiber.sleep(MAXWAIT + 1)
    res = mon.info(wat.wid)
    prop = (not res.ans) and (res.match == 2) and (res.nomatch == 4)
    t:is(prop, true, 'Some items on the list have not been removed')

    --FWD11
    MAXWAIT = 4
    local file_list_3 = {f6, f7, f8, f9}
    fiber.create(helper.remove_file, f6, 1)
    fiber.create(helper.remove_file, f7, 1)
    fiber.create(helper.remove_file, f9, 1)
    wat = fwt.deletion(file_list_3, MAXWAIT, INTERVAL, {nil, nil, 3})
    fiber.sleep(MAXWAIT)
    res = mon.info(wat.wid)
    prop = (res.ans) and (res.match == 3) and (res.nomatch == 1)
    t:is(prop, true, 'The number of cases has been eliminated')

    --FWD12
    helper.remove_tmp_files(0)
    fiber.sleep(1)
    for _=1,10 do os.tmpname() end
    local file_pattern = {'/tmp/lua_*'}
    wat = fwt.deletion(file_pattern, MAXWAIT, INTERVAL)
    fiber.sleep(MAXWAIT + 1)
    res = mon.info(wat.wid)
    prop = (not res.ans) and (res.match == 0)
    t:is(prop, true, 'No pattern elements have been removed')

    --FWD13
    MAXWAIT = 6
    os.execute('touch /tmp/FAD_aaaaa')
    os.execute('touch /tmp/FAD_abaaa')
    os.execute('touch /tmp/FAD_acaaa')
    os.execute('touch /tmp/FAD_adaaa')
    wat = fwt.deletion({'/tmp/FAD_*'}, MAXWAIT, INTERVAL)
    fiber.create(helper.remove_file, '/tmp/FAD_aaaaa', 1)
    fiber.create(helper.remove_file, '/tmp/FAD_abaaa', 1)
    fiber.create(helper.remove_file, '/tmp/FAD_acaaa', 1)
    fiber.create(helper.remove_file, '/tmp/FAD_adaaa', 1)
    fiber.sleep(MAXWAIT)
    res = mon.info(wat.wid)
    prop = (res.ans) and (res.match == 4)
    t:is(prop, true, 'All the pattern files have been deleted')

    --FWD14
    local folder = {'/tmp/thefolder'}
    os.execute('mkdir /tmp/thefolder')
    os.execute('touch /tmp/thefolder/tst1.txt')
    os.execute('touch /tmp/thefolder/tst2.txt')
    os.execute('touch /tmp/thefolder/tst3.txt')
    wat = fwt.deletion(folder, MAXWAIT, INTERVAL)
    fiber.create(helper.remove_tmp_folder, 3)
    fiber.sleep(MAXWAIT + 1)
    res = mon.info(wat.wid)
    prop = (res.ans) and (res.match == 1)
    t:is(prop, true, 'The folder has been deleted')

    --FWD15
    MAXWAIT = 5
    os.execute('touch /tmp/tst1.txt')
    os.execute('touch /tmp/tst2.txt')
    os.execute('touch /tmp/tst3.txt')
    os.execute('touch /tmp/tst4.txt')
    os.execute('touch /tmp/tst5.abc')
    os.execute('touch /tmp/tst6.abc')

    local watcher_mix = {'/tmp/tst*.txt', '/tmp/tst6.abc'}
    wat = fwt.deletion(watcher_mix, MAXWAIT, INTERVAL)
    fiber.create(helper.remove_pattrn, '/tmp/tst*.txt', 3)
    fiber.create(helper.remove_file, '/tmp/tst6.abc', 1)
    fiber.sleep(MAXWAIT)
    res = mon.info(wat.wid).ans
    t:is(res, true, 'Combine lists and patterns together')

    --FWD16
    os.execute('touch /tmp/f_G.txt')
    os.execute('touch /tmp/f_H.txt')
    os.execute('touch /tmp/f_I.txt')
    os.execute('touch /tmp/f_J.txt')
    os.execute('touch /tmp/f_K.txt')
    os.execute('touch /tmp/f_L.txt')

    n_match = 2

    wat = fwt.deletion({'/tmp/f_*'}, MAXWAIT, INTERVAL, {'AA', 3, n_match})
    fiber.create(helper.remove_file, '/tmp/f_G.txt', 1)
    fiber.create(helper.remove_file, '/tmp/f_L.txt', 1)
    fiber.create(helper.remove_file, '/tmp/f_K.txt', 2)
    fiber.sleep(MAXWAIT)
    res = mon.info(wat.wid)
    prop = (res.ans) and (res.match >= 2) and (res.match <= 3)
    t:is(prop, false, 'Match first 2 from 3 fst items ordered by change Alpha Asc')

    --FWD17
    helper.remove_pattrn('/tmp/f_*', 0)
    os.execute('touch /tmp/f_G.txt')
    os.execute('touch /tmp/f_H.txt')
    os.execute('touch /tmp/f_I.txt')
    os.execute('touch /tmp/f_J.txt')
    os.execute('touch /tmp/f_K.txt')
    os.execute('touch /tmp/f_L.txt')
    wat = fwt.deletion({'/tmp/f_*'}, MAXWAIT, INTERVAL, {'AD', 3, n_match})
    fiber.create(helper.remove_file, '/tmp/f_G.txt', 1)
    fiber.create(helper.remove_file, '/tmp/f_L.txt', 1.3)
    fiber.create(helper.remove_file, '/tmp/f_K.txt', 1.5)
    fiber.sleep(MAXWAIT + 1)
    res = mon.info(wat.wid)
    prop = (res.ans) and (res.match >= 2) and (res.match <= 3) and (res.nomatch == 1)
    t:is(res.ans, true, 'Match first 2 from 3 fst items ordered by change Alpha Dsc')

    --FWD18
    helper.remove_pattrn('/tmp/f_*', 0)
    fiber.sleep(1)
    os.execute('touch /tmp/f_1.txt')
    fiber.sleep(1)
    os.execute('touch /tmp/f_2.txt')
    fiber.sleep(1)
    os.execute('touch /tmp/f_3.txt')
    fiber.sleep(1)
    os.execute('touch /tmp/f_4.txt')
    fiber.sleep(1)

    MAXWAIT = 5
    wat = fwt.deletion({'/tmp/f_*'}, MAXWAIT, INTERVAL, {'MA', 3, n_match})
    fiber.create(helper.remove_file, '/tmp/f_1.txt', 2)
    fiber.create(helper.remove_file, '/tmp/f_3.txt', 1)
    fiber.sleep(MAXWAIT + 1)
    res = mon.info(wat.wid)
    prop = (res.ans) and (res.match >= 2) and (res.match <= 3)
    t:is(prop, true, 'Match first 2 from 3 fst items ordered by change Mtime Asc')

    --FWD19
    helper.remove_pattrn('/tmp/f_*', 0)
    os.execute('touch /tmp/f_1.txt')
    fiber.sleep(0.8)
    os.execute('touch /tmp/f_2.txt')
    fiber.sleep(1)
    os.execute('touch /tmp/f_3.txt')
    fiber.sleep(0.5)
    os.execute('touch /tmp/f_4.txt')

    wat = fwt.deletion({'/tmp/f_*'}, MAXWAIT, INTERVAL, {'MD', 3, n_match})
    fiber.create(helper.remove_file, '/tmp/f_2.txt', 1)
    fiber.create(helper.remove_file, '/tmp/f_3.txt', 1.5)
    fiber.sleep(MAXWAIT + 3)
    res = mon.info(wat.wid)
    prop = (res.ans) and (res.match >= 2) and (res.match <= 3)
    t:is(prop, true, 'Match first 2 from 3 fst items ordered by change Mtime Dsc')

    --FWD20
    helper.remove_pattrn('/tmp/f_*', 0)
    fiber.sleep(2)
    os.execute('touch /tmp/f_1.txt')
    os.execute('touch /tmp/f_2.txt')
    os.execute('touch /tmp/f_3.txt')
    os.execute('touch /tmp/f_4.txt')

    wat = fwt.deletion({'/tmp/f_*'}, MAXWAIT, INTERVAL, {'NS', 3, n_match})
    fiber.create(helper.remove_file, '/tmp/f_1.txt', 1)
    fiber.create(helper.remove_file, '/tmp/f_4.txt', 1)
    fiber.sleep(MAXWAIT + 1)
    res = mon.info(wat.wid)
    prop = (not res.ans) and (res.match == 1) and (res.nomatch == 2)
    t:is(prop, true, 'Match only one of 3 las cases no sorted')

end)

--Plan 5
test:test('Single File Creation', function(t)

    t:plan(3)

    MAXWAIT = 3
    INTERVAL = 0.5

    --FWD21
    local c1 = os.tmpname()
    wat = fwt.creation({c1}, MAXWAIT, INTERVAL)
    fiber.sleep(MAXWAIT)
    res = mon.info(wat.wid)
    t:is(res.ans, true, 'The file already existed')

    --FWD22
    wat = fwt.creation({c1}, MAXWAIT, INTERVAL)
    helper.create_file('/tmp/c_fdw022', 2)
    fiber.sleep(MAXWAIT + 1)
    res = mon.info(wat.wid)
    t:is(res.ans, true, 'The file has arrived!')

    --FWD23
    wat = fwt.creation({'/tmp/c_f_d_w_0_2_3'}, MAXWAIT, INTERVAL)
    fiber.sleep(MAXWAIT + 1)
    res = mon.info(wat.wid)
    t:is(res.ans, false, 'The file has not been created')

    helper.remove_pattrn('/tmp/c_*', 0)

end)

--Plan 6
test:test('Advanced File Creation', function(t)

    t:plan(4)

    MAXWAIT = 4
    INTERVAL = 0.5

    local c1 = os.tmpname()
    wat = fwt.creation({c1}, MAXWAIT, INTERVAL, 10)
    fiber.sleep(MAXWAIT + 1)
    res = mon.info(wat.wid)
    t:is(res.ans, false, 'The file size not expected')

    helper.append_file(c1, 2)
    wat = fwt.creation({c1}, MAXWAIT, INTERVAL, 10)
    fiber.sleep(MAXWAIT + 1)
    res = mon.info(wat.wid)
    t:is(res.ans, true, 'The file size has arrived!')

    --fiber.create(append_file, c1, 2)

    helper.remove_tmp_files(0)
    wat = fwt.creation({'/tmp/lua_*'}, nil, nil, 0, nil, nil, 2000)
    fiber.create(helper.create_nfiles, 2000)
    fiber.sleep(MAXWAIT + 1)
    res = mon.info(wat.wid)
    prop = (res.ans) and (res.match == 2000)
    t:is(prop, true, '2000 files are expected and 2000 files arrive')

    MAXWAIT = 5
    helper.remove_tmp_files(0)
    wat = fwt.creation({'/tmp/lua_*'}, MAXWAIT, nil, 0, nil, nil, 2100)
    fiber.create(helper.create_nfiles, 2000)
    fiber.sleep(MAXWAIT + 1)
    res = mon.info(wat.wid)
    t:is(res.ans, false, '2100 files are expected but only 2000 arrive')

    --[[helper.remove_tmp_files(0)
    local c2 = os.tmpname()
    wat = fwt.creation({c2}, 10, INTERVAL, 10)
    fiber.create(helper.remove_file, c2, 0)
    fiber.sleep(MAXWAIT + 1)
    res = mon.info(wat.wid)
    t:is(res.ans, false, 'The file has unexpectedly disappeared')
    --]]
end)

print('Elapsed time: ' .. os.difftime(os.time() - pini) .. 's')

os.exit(test:check() == true and 0 or -1)

return {
    test = test
}
