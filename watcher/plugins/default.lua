#!/usr/bin/env tarantool
------------
-- User defined Plugins
-- ...
-- @module <Module name>
-- @author <The Author>
-- @license <MIT>
-- @copyright <Name Year>

-- User space definition
local function user_spaces_def()
    print('USER SPACE DEFINITION')
    return true
end

return {
    user_spaces_def = user_spaces_def
}