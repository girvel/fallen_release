local zone = require("jit.zone")
local profile = require("jit.profile")
local jit_profile = {}

local samples, total_samples

--- @param group_by_lines boolean
--- @param group_by_zones boolean
--- @param group_by_state boolean
jit_profile.start = function(group_by_lines, group_by_zones, group_by_state)
  samples = {}
  total_samples = 0
  local type = group_by_lines and "l" or "f"
  profile.start(type.." i1", function(thread, samples_n, vm_state)
    local place = profile.dumpstack(thread, "F", 1) or "[C/JIT Code]"
    if group_by_zones then
      place = place.."/"..(zone:get() or "-")
    end
    if group_by_state then
      place = place.."/"..vm_state
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
    -- local sample = sorted[1]
    -- if sample.zone then
    --   header = header.." Zone    |"
    -- end
    -- if sample.vm_state then
    --   header = header.. " VM State |"
    -- end
    header = header.." Place"
    out = {header, string.rep("-", #header)}
  end

  for i = 1, math.min(limit, #sorted) do
    local s = sorted[i]
    local percent = (s.count / total_samples) * 100
    -- local vm_state_repr = vm_states_reprs[s.vm_state] or s.vm_state
    table.insert(out, string.format(
      " %5.2f%% | %-7d | %s",
      percent, s.count, s.f
    ))
  end

  return table.concat(out, "\n")
end

return jit_profile
