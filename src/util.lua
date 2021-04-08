--http://lua-users.org/wiki/TableUtils
local function val_to_str(v)
    if "string" == type(v) then
      v = string.gsub(v, "\n", "\\n")
      if string.match(string.gsub(v,"[^'\"]",""), '^"+$' ) then
        return "'" .. v .. "'"
      end
      return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
    else
      return "table" == type(v) and tostring(v) or
        tostring(v)
    end
  end

  local function key_to_str(k)
    if "string" == type(k) and string.match(k, "^[_%a][_%a%d]*$") then
      return k
    else
      return "[" .. val_to_str(k) .. "]"
    end
  end

  local function tostring(tbl)
    local result, done = {}, {}
    for k, v in ipairs(tbl) do
      table.insert(result, val_to_str(v))
      done[k] = true
    end
    for k, v in pairs(tbl) do
      if not done[k] then
        table.insert(result,
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

  local util = {
    tostring = tostring,
    is_valof = is_valof,
    is_keyof = is_keyof
  }

  return util