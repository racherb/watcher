#!/usr/bin/env tarantool

local kit = require('watcher')
local tap = require('tap')

local test = tap.test('watcher tests')
test:plan(1)

test:test('watcher', function(test)
    test:plan(1)
    test:is(kit.test(1), 11, "Lua function in init.lua")
end)

os.exit(test:check() == true and 0 or -1)
