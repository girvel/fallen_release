local zone = require("jit.zone")
local profile = require("jit.profile")
local jit_profile = {}

local samples, total_samples

--- @class jit_profile.group_by
--- @field line boolean
--- @field zone boolean
--- @field state boolean

--- @type jit_profile.group_by
local group_by

--- @param grouping jit_profile.group_by
jit_profile.start = function(grouping)
  samples = {}
  total_samples = 0
  group_by = grouping

  local type = group_by.line and "l" or "f"
  profile.start(type.." i1", function(thread, samples_n, vm_state)
    local place = profile.dumpstack(thread, group_by.line and "pl" or "F", 1) or "[C/JIT Code]"
    if group_by.state then
      place = place.."/"..vm_state
    end
    if group_by.zone then
      place = place.."/"..(zone:get() or "-")
    end
    samples[place] = (samples[place] or 0) + samples_n
    total_samples = total_samples + samples_n
  end)
end

jit_profile.stop = function()
  profile.stop()
end

local vm_states_reprs = {
  N = "JIT code",
  I = "Lua code",
  C = "C code",
  G = "GC",
  J = "Compiling",
}

jit_profile.report = function(limit)
  if not samples then
    return "<profiler did not run>"
  end

  limit = limit or 20
  local sorted = {}
  for place, count in pairs(samples) do
    table.insert(sorted, {f = place, count = count})
  end
  table.sort(sorted, function(a, b) return a.count > b.count end)

  local out do
    local header = " Share  | Samples |"
    if group_by.zone then
      header = header.." Zone           |"
    end
    if group_by.state then
      header = header.. " VM State  |"
    end
    header = header.." Place"
    out = {header, string.rep("-", #header)}
  end

  for i = 1, math.min(limit, #sorted) do
    local s = sorted[i]
    local percent = (s.count / total_samples) * 100
    local line = string.format(" %5.2f%% | %-7d ", percent, s.count)
    local place = s.f
    if group_by.zone then
      local this_zone
      place, this_zone = place:match("^(.*)/([^/]+)$")
      line = line..string.format("| %-14s ", this_zone)
    end
    if group_by.state then
      local state
      place, state = place:match("^(.*)/(.)$")
      line = line..string.format("| %-9s ", vm_states_reprs[state] or state)
    end
    line = line.."| "..place
    table.insert(out, line)
  end

  return table.concat(out, "\n")
end

return jit_profile
