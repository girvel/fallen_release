local file, times, prev_time, index

--- MP stands for Manual Profiler
--- 
--- Call this function before every line that needs profiling
--- @param report? "report"|"first"
--- @return string?
local mp = function(report)
  if report == "report" then
    if not file then return end
    local result = ""
    local lines = file:split("\n")
    local time_i = 1
    for i, line in ipairs(lines) do
      if i > 1 then result = result.."\n" end
      local next_line, mods_n = line:gsub("Mp%([^)]*%); ", "")
      if mods_n > 0 then
        if 
        result = result..("\t%.2f s\t%s"):format(times[time_i], next_line)
        time_i = time_i + 1
      else
        result = result.."\t\t"..line
      end
    end
    return result
  end

  local t = love.timer.getTime()

  if not file then
    file = love.filesystem.read(debug.getinfo(2, "S").short_src)
    times = {}
    local i = -1
    for _ in file:gmatch("Mp%([^)]*%)") do
      i = i + 1
      times[i] = 0
    end
    index = 0
  end

  if report == "first" then
    index = 1
  else
    times[index] = times[index] + t - prev_time
    index = index + 1
  end
  prev_time = t
end

return mp
