local sound = require("engine.tech.sound")
local animated = require("engine.tech.animated")
local colors = require("engine.tech.colors")
local floater = require("engine.tech.floater")
local xp = {}

--- xp.for_level[X] is total XP to get from level 0 to level X
xp.for_level = {[0] = 0, 0, 300, 900, 2700, 6500}

--- Amount of XP you get for passed ability check
xp.check = 10

-- TODO move
--- How much points does it cost to get the ability score (xp.point_buy[ability score] == points)
xp.point_buy = {
  [8] = 0,
  [9] = 1,
  [10] = 2,
  [11] = 3,
  [12] = 4,
  [13] = 5,
  [14] = 7,
  [15] = 9,
}

--- @param level integer
--- @return integer
xp.get_proficiency_bonus = function(level)
  return 1 + math.ceil(level / 4)
end

--- Amount of XP between (level) and (level - 1)
--- @param level integer
--- @return integer
xp.to_reach = function(level)
  assert(level >= 0)
  local this = xp.for_level[level]
  local prev = xp.for_level[level - 1]
  if not this or not prev then return math.huge end
  return this - prev
end

local LEVEL_UP_SOUND = sound.new("assets/sounds/level_up.mp3")

--- @param target entity
--- @param amount number
xp.reward = function(target, amount)
  if target == State.player then
    Log.debug("%s XP", amount)
  end
  State:add(floater.new("+"..amount, target.position, colors.yellow))

  local xp_to_next_level = xp.to_reach(target.level + 1)
  local xp_before = target.xp
  target.xp = target.xp + amount
  if xp_before < xp_to_next_level and target.xp >= xp_to_next_level then
    animated.add_fx("engine/assets/animations/level_up", target.position, "fx_under")
    LEVEL_UP_SOUND
      :clone()
      :place(target.position)
      :play()
  end
end

Ldump.mark(xp, {}, ...)
return xp
