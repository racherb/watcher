#!/usr/bin/env tarantool

local kit = require('watcher').file
local tap = require('tap')

local test = tap.test('test-watcher')
test:plan(1)

test:test('single_file_deletion_file_not_exist', function(test)
    test:plan(1)
    test:is(kit.deletion({'/tmp/abb'}), true, "The file don't exist")
end)

ans, b, c = kit.deletion({'/tmp/abb'})

print(ans)
print(b)
print(c)

os.exit(test:check() == true and 0 or -1)

return {
    test = test
}