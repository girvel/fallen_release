local stages = {}

--- @class stages
--- @field warmup stages.warmup
--- @field detective stages.detective

--- @return stages
stages.new = function()
  --- @enum (key) stages.keys
  local result = {
    warmup = 0,
    detective = 0,
  }
  return result
end

stages.NONE = 0
stages.COMPLETED = 1000

--- @enum stages.warmup
stages.warmup = {
  _0010_intro_heard = 10,
  _0020_needs_to_leave = 20,
  _0030_left = 30,
  _0040_in_room = 40,
  _0050_weapon_picked_up = 50,
  _0060_practiced = 60,
  _0070_mirage_defeated = 70,
  _1000_bird_fed = stages.COMPLETED,
}

--- @enum stages.detective
stages.detective = {
  _1000_completed = stages.COMPLETED,
}

Ldump.mark(stages, {mt = "const"}, ...)
return stages
