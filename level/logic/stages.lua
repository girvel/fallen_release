local stages = {}

--- @class stages
--- @field warmup stages.warmup

--- @return stages
stages.new = function()
  return {
    warmup = 0,
  }
end

stages.NONE = 0
stages.COMPLETED = 1000

--- @enum stages.warmup
stages.warmup = {
  intro_heard = 10,
  note_picked_up = 20,
  note_read = 30,
  left = 35,
  in_room = 40,
  weapon_picked_up = 50,
  practiced = 60,
  mirage_defeated = 70,
  bird_fed = stages.COMPLETED,
}

Ldump.mark(stages, {mt = "const"}, ...)
return stages
