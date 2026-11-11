local ini = {}

--- @param path string
--- @return table<string, string>
ini.read = function(path)
  local content do
    local f = assert(io.open(path, "r"))
    content = f:read("*a")
    f:close()
  end

  local result = {}
  for i, line in ipairs(content:split("%s*\n%s*")) do
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
    elseif value:starts_with('"') and value:ends_with('"') then
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

  do
    local f = assert(io.open(path, "w"))
    f:write(table.concat(result, "\n"))
    f:close()
  end
end

return ini
