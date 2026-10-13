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
    if value:starts_with('"') and value:ends_with('"') then
      value = value:sub(2, -2)
    end
    result[key] = value
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
    result[i] = k.."="..v
  end
  
  do
    local f = assert(path, "w")
    f:write(table.concat(result, "\n"))
    f:close()
  end
end

return ini
