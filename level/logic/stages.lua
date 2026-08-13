local stages = {}

--- @class stages
--- @field warmup stages.warmup
--- @field detective stages.detective
--- @field parasites stages.parasites
--- @field alcohol stages.alcohol
--- @field sigi stages.sigi

--- @return stages
stages.new = function()
  --- @enum (key) stages.keys
  local result = {
    warmup = 0,
    detective = 0,
    parasites = 0,
    alcohol = 0,
    sigi = 0,
  }
  return result
end

stages.NONE = 0
stages.COMPLETED = 1000
stages.FAILED = 2000

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
  _0010_black_door = 10,
  _0020_investigate = 20,
  _1000_completed = stages.COMPLETED,
  _2000_failed = stages.FAILED,
}

--- @enum stages.parasites
stages.parasites = {
  _0010_go_to_bridge = 10,
  _0020_unlock_starboard = 20,
  _0030_kill_parasites = 30,
  _1000_completed = stages.COMPLETED,
}

--- @enum stages.alcohol
stages.alcohol = {
  _0010_search = 10,
  _0020_search_again = 20,
  _0030_return = 30,
  _1000_completed = 1000,
}

--- @enum stages.sigi
stages.sigi = {
  _0010_search = 10,
  _0020_return = 20,
  _1000_completed = stages.COMPLETED,
  _2000_failed = stages.FAILED,
}

Ldump.mark(stages, {mt = "const"}, ...)
return stages
