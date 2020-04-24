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
    id1 = '[FW_PATH_ISEMPTY]        Nothing for watch',
    id2 = '{CHECK MSSG CODE}        The message is correct',
    id3 = "[FW_UNKNOWN_NOT_EXISTS]  The file don't exist",
    id4 = '{NO WAIT MAXWAIT}        No wait if file not exist',
    id5 = "[FW_UNKNOWN_NOT_EXISTS]  The path don't exist",
    id6 = '[FW_FILE_NOT_DELETED]    The file has not been deleted',
    id7 = '[FW_FILE_NOT_DELETED]    File not deleted in the maxwait interval',
    id8 = '[FW_FILE_DELETED]        The file has been deleted',
    id9 = '[FW_NOTHING_DELETED]     No file on the list has been removed',
    id10= '[FW_ALL_DELETED]         All files have been deleted',
    id11= '[FW_MATCH_NOT_DELETED]   Some items on the list have not been removed',
    id12= '[FW_MATCH_DELETED]       The number of cases has been eliminated',
    id13= '[FW_NOTHING_DELETED]     No pattern elements have been removed',
    id14= '[FW_ALL_DELETED]         All the pattern files have been deleted',
    id15= '[FW_DIR_DELETED]         The folder has been deleted',
    id16= '[FW_ALL_DELETED]         Combine lists and patterns together',
    id17= '[FW_MATCH_DELETED]       Match first N items ordered by change date asc',
    id18= '[FW_MATCH_DELETED]       Return of the first match N items'
}

local test = tap.test('test-file-watcher')
test:plan(4)
local pini = os.time()
test:test('single_file_deletion:file_not_exist', function(test)
    test:plan(6)
    local ans, mssg = fwt.deletion({''})
    test:is(ans, false, TEST.id1)
    test:is(mssg, 'FW_PATH_ISEMPTY', TEST.id2)
    local file_not_exist_yet = '_THIS.NOT$_?EXIST%'
    local ans, mssg, _ = fwt.deletion({file_not_exist_yet})
    test:is(ans, true, TEST.id3)
    test:is(mssg, 'FW_UNKNOWN_NOT_EXISTS', TEST.id2)
    local MAXWAIT = 5
    local tini = os.time()
    local _ = fwt.deletion({'/tmp/' .. file_not_exist_yet}, MAXWAIT)
    local elapsed_time = os.difftime(os.time() - tini)
    test:ok(elapsed_time < MAXWAIT, TEST.id4)
    local folder_not_exist_yet = '/tmp/THIS_FOLDER_NOT_EXIST/'
    local ans = fwt.deletion({folder_not_exist_yet})
    test:is(ans, true, TEST.id5)
end)

test:test('single_file_deletion:file_exist_not_deleted', function(test)
    test:plan(3)
    local MAXWAIT = 10
    local this_file_exist = os.tmpname()
    local ans, mssg, _ = fwt.deletion({this_file_exist}, MAXWAIT)
    test:is(ans, false, TEST.id6)
    test:is(mssg, 'FW_FILE_NOT_DELETED', TEST.id2)

    local MAXWAIT = 5
    fiber.create(remove_file, this_file_exist, 10)
    local ans = fwt.deletion({this_file_exist}, MAXWAIT)
    test:is(ans, false, TEST.id7)
end)

test:test('single_file_deletion:file_exist_deleted', function(test)
    test:plan(2)
    local MAXWAIT = 10
    local this_file_exist = os.tmpname()
    fiber.create(remove_file, this_file_exist, 5)
    local ans, mssg, _ = fwt.deletion({this_file_exist}, MAXWAIT)
    test:is(ans, true, TEST.id8)
    test:is(mssg, 'FW_FILE_DELETED', TEST.id2)
end)

test:test('multiple_file_deletion:list_experiments', function(test)
    test:plan(19)
    local MAXWAIT = 3
    local INTERVAL = 0.5
    local f1 = os.tmpname()
    local f2 = os.tmpname()
    local f3 = os.tmpname()
    local file_list = {f1, f2, f3}
    local ans, mssg = fwt.deletion(file_list, MAXWAIT, INTERVAL)
    test:is(ans, false, TEST.id9)
    test:is(mssg, 'FW_NOTHING_DELETED', TEST.id2)

    local MAXWAIT = 8
    fiber.create(remove_file, f1, 1)
    fiber.create(remove_file, f2, 2)
    fiber.create(remove_file, f3, 3)
    local ans, mssg = fwt.deletion(file_list, MAXWAIT, INTERVAL)
    test:is(ans, true, TEST.id10)
    test:is(mssg, 'FW_ALL_DELETED', TEST.id2)

    local f4 = os.tmpname()
    local f5 = os.tmpname()
    local f6 = os.tmpname()
    local f7 = os.tmpname()
    local f8 = os.tmpname()
    local f9 = os.tmpname()
    local file_list_2 = {f4, f5, f6, f7, f8, f9}
    fiber.create(remove_file, f4, 1)
    fiber.create(remove_file, f5, 3)
    local ans, mssg = fwt.deletion(file_list_2, MAXWAIT, INTERVAL)
    test:is(ans, false, TEST.id11)
    test:is(mssg, 'FW_MATCH_NOT_DELETED', TEST.id2)

    local MAXWAIT = 10
    local file_list_3 = {f6, f7, f8, f9}
    fiber.create(remove_file, f6, 1)
    fiber.create(remove_file, f7, 3)
    fiber.create(remove_file, f9, 1)
    local options = {nil, 3, 2}
    local ans, mssg = fwt.deletion(file_list_3, MAXWAIT, INTERVAL, options)
    test:is(ans, true, TEST.id12)
    test:is(mssg, 'FW_MATCH_DELETED', TEST.id2)

    for _=1,10 do os.tmpname() end
    local file_pattern = {'/tmp/*'}
    local ans, mssg = fwt.deletion(file_pattern, MAXWAIT, INTERVAL)
    test:is(ans, false, TEST.id13)
    test:is(mssg, 'FW_NOTHING_DELETED', TEST.id2)

    local MAXWAIT = 5
    for _=1,9 do os.tmpname() end
    fiber.create(remove_tmp_files, 3)
    local ans, mssg = fwt.deletion(file_pattern, MAXWAIT, INTERVAL)
    test:is(ans, true, TEST.id14)
    test:is(mssg, 'FW_ALL_DELETED', TEST.id2)

    local folder = {'/tmp/thefolder'}
    os.execute('mkdir /tmp/thefolder')
    os.execute('touch /tmp/thefolder/tst1.txt')
    os.execute('touch /tmp/thefolder/tst2.txt')
    os.execute('touch /tmp/thefolder/tst3.txt')
    fiber.create(remove_tmp_files, 3)
    local ans, mssg = fwt.deletion(folder, MAXWAIT, INTERVAL)
    test:is(ans, true, TEST.id15)
    test:is(mssg, 'FW_DIR_DELETED', TEST.id2)

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
    local ans, mssg = fwt.deletion(watcher_mix, MAXWAIT, INTERVAL)
    test:is(ans, true, TEST.id16)
    test:is(mssg, 'FW_ALL_DELETED', TEST.id2)

    local MAXWAIT = 7
    local INTERVAL = 0.5
    os.execute('touch /tmp/f_a.txt')
    fiber.sleep(1) os.execute('touch /tmp/f_b.txt')
    fiber.sleep(1) os.execute('touch /tmp/f_c.txt')
    fiber.sleep(1) os.execute('touch /tmp/f_d.txt')
    fiber.sleep(1) os.execute('touch /tmp/f_e.txt')
    fiber.sleep(1) os.execute('touch /tmp/f_f.txt')
    fiber.create(remove_file, '/tmp/f_b.txt', 1)
    fiber.create(remove_file, '/tmp/f_c.txt', 1)
    local n_match = 2
    local options = {'MTIME_ASC', 3, n_match}
    local ans, mssg, obj = fwt.deletion({'/tmp/f_*'}, MAXWAIT, INTERVAL, options)
    test:is(ans, true, TEST.id17)
    test:is(mssg, 'FW_MATCH_DELETED', TEST.id2)
    test:is(#obj, n_match, TEST.id18)

end)

print('Elapsed time: ' .. os.difftime(os.time() - pini) .. 's')

os.exit(test:check() == true and 0 or -1)

return {
    test = test
}