local ini = {}

--- @param str string
--- @param pat string
--- @param plain boolean?
--- @return string[]
local split = function(str, pat, plain)
  local t = {}

  while true do
    local pos1, pos2 = str:find(pat, 1, plain or false)

    if not pos1 or pos1 > pos2 then
      t[#t + 1] = str
      return t
    end

    t[#t + 1] = str:sub(1, pos1 - 1)
    str = str:sub(pos2 + 1)
  end
end

--- @param str string
--- @param prefix string
--- @return boolean
local starts_with = function(str, prefix)
  return str:sub(1, #prefix) == prefix
end

--- @param str string
--- @param postfix string
--- @return boolean
local ends_with = function(str, postfix)
  return str:sub(-#postfix, -1) == postfix
end

ini.read_f = function(path)
  local f = assert(io.open(path, "r"))
  local content = f:read("*a")
  f:close()
  return content
end

ini.write_f = function(path, content)
  local f = assert(io.open(path, "w"))
  f:write(content)
  f:close()
end

--- @param path string
--- @return table<string, any>
ini.read = function(path)
  local content = ini.read_f(path)

  local result = {}
  for i, line in ipairs(split(content, "%s*\n%s*")) do
    if #line == 0 then goto continue end
    local j = line:find("=")
    if not j then
      error("Config line #"..i.." contains no =")
    end
    local key = line:sub(1, j - 1)
    local value = line:sub(j + 1)
    local value_as_a_number = tonumber(value)
    if value_as_a_number then
      result[key] = value_as_a_number
    elseif starts_with(value, '"') and ends_with(value, '"') then
      result[key] = value:sub(2, -2)
    elseif value == "true" then
      result[key] = true
    elseif value == "false" then
      result[key] = false
    else
      error(string.format("Unknown ini value %q", value))
    end
    ::continue::
  end
  return result
end

--- @param path string
--- @param obj table
ini.write = function(path, obj)
  local sorted = {}
  for k, v in pairs(obj) do
    table.insert(sorted, {tostring(k), tostring(v)})
  end
  table.sort(sorted, function(a, b) return a[1] < b[1] end)

  local result = {}
  for i, pair in ipairs(sorted) do
    local k, v = unpack(pair)

    local k_type = type(k)
    if k_type ~= "string" then
      error(string.format(".ini keys should be strings, got %q", k_type))
    end

    local v_type = type(v)
    if v_type == "string" then
      result[i] = k..'="'..v..'"'
    elseif v_type == "boolean" or v_type == "number" then
      result[i] = k..'='..v
    else
      error(".ini does not support "..v_type.." value type")
    end
  end

  ini.write_f(path, table.concat(result, "\n"))
end

return ini
