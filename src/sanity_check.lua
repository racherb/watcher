#!/usr/bin/env tarantool
------------
-- Sanity Check
-- Sanity Check for user Inputs
--
-- @module watcher
-- @author hernandez, raciel
-- @license MIT
-- @copyright Raciel Hernández 2021
--

local OUTPUT = require('types.file').OUTPUT

local sanity_check = {}

local function validate_wlist(wlist)
    if (wlist) and (type(wlist)=='table') and (#wlist~=0) then
        return {
            ans = true,
            msg = 'okay'
        }
    else
        return{
            ans = false,
            msg = OUTPUT.WATCH_LIST_NOT_VALID
        }
    end
end

local function validate_maxwait(maxwait)
    if (maxwait) and (type(maxwait)=='number') and (maxwait > 0) then
        return {
            ans = true,
            msg = 'okay'
        }
    else
        return{
            ans = false,
            msg = OUTPUT.MAXWAIT_NOT_VALID
        }
    end
end

local function validate_interval(interval, maxwait)
    if (interval) and (type(interval)=='number') and (interval > 0) then
        if maxwait and maxwait > interval then
            return {
                ans = true,
                msg = 'okay'
            }
        else
            return{
                ans = false,
                msg = OUTPUT.INTERVAL_NOT_IN_RANGE
            }
        end
    else
        return{
            ans = false,
            msg = OUTPUT.INTERVAL_NOT_VALID
        }
    end
end

local function validate_minsize(size)
    if (size) and (type(size)=='number') and (size >= 0) then
        return {
            ans = true,
            msg = 'okay'
        }
    else
        return {
            ans = false,
            msg = OUTPUT.MINSIZE_NOT_VALID
        }
    end
end

local function validate_stability(stability)
    if (stability) and (type(stability)=='table') and (#stability~=0) then
        if (stability[1]) and (type(stability[1])=='number') and (stability[1]>0) then
            if (stability[2]) and (type(stability[2])=='number') and (stability[2]>0) then
                return {
                    ans = true,
                    msg = 'okay'
                }
            else
                return {
                    ans = false,
                    msg =  OUTPUT.ITERATIONS_NOT_VALID
                }
            end
        else
            return {
                ans = false,
                msg = OUTPUT.CHECK_SIZE_INTERVAL_NOT_VALID
            }
        end
    else
        return {
            ans = false,
            msg = OUTPUT.STABILITY_NOT_VALID
        }
    end
end

local function validate_novelty(novelty)
    if (novelty) and (type(novelty)=='table') and (#novelty~=0) then
        if (novelty[1]) and (type(novelty[1])=='number') then
            if (novelty[2]) and (type(novelty[2])=='number') then
                if (novelty[2] >= novelty[1]) then
                    return {
                        ans = true,
                        msg = 'okay'
                    }
                else
                    return {
                        ans = false,
                        msg = OUTPUT.NOVELTY_BAD_RANGE
                    }
                end
            else
                return {
                    ans = false,
                    msg = OUTPUT.DATE_UNTIL_NOT_VALID
                }
            end
        else
            return {
                ans = false,
                msg = OUTPUT.DATE_FROM_NOT_VALID
            }
        end
    else
        return {
            ans = false,
            msg = OUTPUT.NOVELTY_NOT_VALID
        }
    end
end

sanity_check.wlist = validate_wlist
sanity_check.maxwait = validate_maxwait
sanity_check.interval = validate_interval
sanity_check.size = validate_minsize
sanity_check.stability = validate_stability
sanity_check.novelty = validate_novelty

return sanity_check