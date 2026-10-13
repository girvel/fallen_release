local config = {}

config.read = function()
  local content = love.filesystem.read("config.ini")
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

Ldump.mark(config, {}, ...)
return config
