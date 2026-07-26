local stages = {}

--- @class stages
--- @field warmup stages.warmup

--- @return stages
stages.new = function()
  --- @enum (key) stages.keys
  local result = {
    warmup = 0,
  }
  return result
end

stages.NONE = 0
stages.COMPLETED = 1000

--- @enum stages.warmup
stages.warmup = {
  intro_heard = 10,
  needs_to_leave = 20,
  left = 30,
  in_room = 40,
  weapon_picked_up = 50,
  practiced = 60,
  mirage_defeated = 70,
  bird_fed = stages.COMPLETED,
}

Ldump.mark(stages, {mt = "const"}, ...)
return stages
