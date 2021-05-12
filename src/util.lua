local type = type
local ipairs = ipairs
local pairs = pairs

local table_insert = table.insert
local string_gsub = string.gsub
local string_match = string.match


--http://lua-users.org/wiki/TableUtils
local function val_to_str(v)
    if "string" == type(v) then
      v = string_gsub(v, "\n", "\\n")
      if string_match(string_gsub(v,"[^'\"]",""), '^"+$' ) then
        return "'" .. v .. "'"
      end
      return '"' .. string_gsub(v,'"', '\\"' ) .. '"'
    else
      return "table" == type(v) and tostring(v) or
        tostring(v)
    end
  end

  local function key_to_str(k)
    if "string" == type(k) and string_match(k, "^[_%a][_%a%d]*$") then
      return k
    else
      return "[" .. val_to_str(k) .. "]"
    end
  end

  local function tostring(tbl)
    local result, done = {}, {}
    for k, v in ipairs(tbl) do
      table_insert(result, val_to_str(v))
      done[k] = true
    end
    for k, v in pairs(tbl) do
      if not done[k] then
        table_insert(result,
          key_to_str(k) .. "=" .. val_to_str(v))
      end
    end
    return "{" .. table.concat(result, ",") .. "}"
  end

  --Determines whether a value exists in a given table
local function is_valof(tbl, value)
  for _,v in pairs(tbl) do
    if v == value then
      return true
    end
  end
  return false
end

-- Determines if a key exists in a given table
local function is_keyof(tbl, key)
    for k,_ in pairs(tbl) do
      if k == key then
        return true
      end
    end
    return false
end

-- Remove duplicate values from a table
local function remove_duplicates(tbl)
  local hash = {}
  local answ = {}

  if #tbl==1 then return tbl end

  for _,v in ipairs(tbl) do
      if not hash[v] then
          answ[#answ+1] = v
          hash[v] = true
      end
  end
  return answ
end

local util = {
  tostring = tostring,
  is_valof = is_valof,
  is_keyof = is_keyof,
  deduplicate = remove_duplicates
}

return util