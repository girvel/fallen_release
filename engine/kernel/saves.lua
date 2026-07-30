local saves = {}

local SLASH = love.system.getOS() == "Windows" and "\\" or "/"

love.filesystem.createDirectory("saves")

--- @async
--- @param target any
--- @param path string
saves.write = function(target, path)
  Log.info("Start saving")

  local t = love.timer.getTime()
  do
    local repr = Ldump(target)
    local compressed = love.data.compress("string", "gzip", repr)
    love.filesystem.write(path, compressed)
  end
  t = love.timer.getTime() - t

  Fun.iter(Ldump.get_warnings()):each(Log.warn)
  local size_kb = love.filesystem.getInfo(path).size / 1024
  local full_path = love.filesystem.getSaveDirectory().."/"..path
  Log.info("%.2f s, %.2f KB | Saved to %s", t, size_kb, full_path)
end

--- @nodiscard
--- @param path string
--- @return any
saves.read = function(path)
  local base = love.filesystem.getSaveDirectory()
  Log.info("Loading from %s%s%s", base, SLASH, path)

  local t = love.timer.getTime()
  local result = assert(loadstring(
    love.data.decompress(
      "string", "gzip", love.filesystem.read(path)
    ) --[[@as string]],
    path
  ))()
  t = love.timer.getTime() - t

  Log.info("Loaded in %.2f s", t)
  return result
end

return saves
