local profile = require("jit.profile")
local jit_profile = {}

local samples, total_samples

jit_profile.start = function()
  samples = {}
  total_samples = 0
  profile.start("f i1", function(thread, samples_n, vm_state)
    local place = profile.dumpstack(thread, "F", 1) or "[C/JIT Code]"
    place = place.."/"..vm_state
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
  limit = limit or 20
  local sorted = {}
  for place, count in pairs(samples) do
    local f, vm_state = place:match("^(.*)/(.)$")
    table.insert(sorted, {f = f, count = count, vm_state = vm_state})
  end
  table.sort(sorted, function(a, b) return a.count > b.count end)

  local out = {"\n--- LuaJIT Sampling Profiler Report ---"}
  table.insert(out, string.format(
    "%-10s | %-10s | %-10s | %s",
    "Share", "Samples", "State", "Function"
  ))
  table.insert(out, string.rep("-", 60))

  for i = 1, math.min(limit, #sorted) do
    local s = sorted[i]
    local percent = (s.count / total_samples) * 100
    local vm_state_repr = vm_states_reprs[s.vm_state] or s.vm_state
    table.insert(out, string.format(
      "%5.2f%%    | %-10d | %-10s | %s",
      percent, s.count, vm_state_repr, s.f
    ))
  end

  return table.concat(out, "\n")
end

return jit_profile
