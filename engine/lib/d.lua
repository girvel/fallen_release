local module_mt = {}
--- @overload fun(sides_n: integer): d.roll
local d = setmetatable({}, module_mt)

local table_new do
  local ok, result = pcall(require, "table.new")
  if ok then
    table_new = result
  else
    table_new = function() return {} end
  end
end

local table_contains = function(t, item)
  for _, x in ipairs(t) do
    if x == item then
      return true
    end
  end
  return false
end

----------------------------------------------------------------------------------------------------
-- [SECTION] Die
----------------------------------------------------------------------------------------------------

--- @class d.dice
--- @field dice_n integer
--- @field sides_n integer
--- @field advantage integer
--- @field comment string?

local ADVANTAGE_CHAR = "↑"
local DISADVANTAGE_CHAR = "↓"

--- @param dice d.dice
local dice_to_string = function(dice)
  local result = ""
  if dice.dice_n ~= 1 or dice.sides_n == 1 then
    result = result..dice.dice_n
  end
  if dice.sides_n ~= 1 then
    result = result.."d"..dice.sides_n
  end

  if dice.advantage > 0 then
    result = result..ADVANTAGE_CHAR
  elseif dice.advantage < 0 then
    result = result..DISADVANTAGE_CHAR
  end

  if dice.comment then
    result = result.." ("..dice.comment..")"
  end
  return result
end

--- @param dice d.dice
--- @param reroll integer[]
--- @return integer
--- @return boolean
local dice_roll = function(dice, reroll)
  if dice.sides_n == 1 then
    return dice.dice_n, false
  end

  local was_there_reroll = false
  local result = 0
  for _ = 1, dice.dice_n do
    local this_roll = math.random(dice.sides_n)
    if dice.advantage > 0 then
      this_roll = math.max(this_roll, math.random(dice.sides_n))
    elseif dice.advantage < 0 then
      this_roll = math.min(this_roll, math.random(dice.sides_n))
    end
    if table_contains(reroll, this_roll) then
      was_there_reroll = true
      this_roll = math.random(dice.sides_n)
    end
    result = result + this_roll
  end
  return result, was_there_reroll
end

--- @param dice d.dice
--- @return d.dice
local dice_copy = function(dice)
  return {
    dice_n = dice.dice_n,
    sides_n = dice.sides_n,
    comment = dice.comment,
    advantage = dice.advantage,
  }
end

----------------------------------------------------------------------------------------------------
-- [SECTION] Dice
----------------------------------------------------------------------------------------------------

--- @class d.roll
--- @field parts d.dice[]
--- @field reroll integer[]
--- @operator add(d.roll): d.roll
--- @operator add(integer): d.roll
--- @operator sub(integer): d.roll
--- @operator mul(integer): d.roll
local methods = {}
d.mt = {__index = methods}

--- @return d.roll
d.new = function()
  return setmetatable({
    parts = {},
    reroll = {},
  }, d.mt)
end

module_mt.__call = function(_, sides_n)
  return d.new():add_die(1, sides_n)
end

--- @param value integer
--- @param comment string?
--- @return d.roll
methods.add_bonus = function(self, value, comment)
  table.insert(self.parts, {
    sides_n = 1,
    dice_n = value,
    comment = comment,
    advantage = 0,
  })
  return self
end

--- @param dice_n integer
--- @param sides_n integer
--- @param comment string?
--- @return d.roll
methods.add_die = function(self, dice_n, sides_n, comment)
  table.insert(self.parts, {
    dice_n = dice_n,
    sides_n = sides_n,
    comment = comment,
    advantage = 0,
  })
  return self
end

--- @param self d.roll
--- @deprecated
d.mt.__add = function(self, other)
  if type(other) == "number" then
    return self:copy():add_bonus(other)
  end

  if type(other) == "table" then
    local copy = self:copy()
    local other_mt = getmetatable(other)
    if other_mt == d.mt then  --- @cast other d.roll
      for _, part in ipairs(other.parts) do
        table.insert(copy.parts, dice_copy(part))
      end
      return copy
    else
      assert(false)
    end
  end

  error("Trying to add "..type(other).." to a dice roll")
end

--- @param self d.roll
d.mt.__sub = function(self, other)
  if type(other) == "number" then
    return self:copy():add_bonus(-other)
  end

  error("Trying to subtract "..type(other).." to a dice roll")
end

--- @param self d.roll
d.mt.__mul = function(self, other)
  if type(other) ~= "number" then
    if type(self) == "number" then
      self, other = other, self
    else
      error("Trying to multiply a dice roll by a "..type(other))
    end
  end

  assert(#self.parts == 1)
  assert(self.parts[1].dice_n == 1)
  local result = self:copy()
  result.parts[1].dice_n = other
  return result
end

--- @param self d.roll
d.mt.__tostring = function(self)
  local result = ""
  for i, part in ipairs(self.parts) do
    if i > 1 then result = result.." + " end
    result = result..dice_to_string(part)
  end

  if #self.reroll > 0 then
    result = result.." 🗘 "..table.concat(self.reroll, ",")
  end

  return result
end

--- @return string
methods.simplified = function(self)
  local min = self:min()
  local max = self:max()
  if min == max then return tostring(min) end
  return ("%s–%s"):format(self:min(), self:max())
end

--- @alias roll.crit_type "nat_20"|"nat_1"

--- @return integer
--- @return roll.crit_type?
methods.roll = function(self)
  local result = 0
  local repr = ""
  local seen_1d20 = false
  local crit_status

  for i, part in ipairs(self.parts) do
    local v, rerolled = dice_roll(part, self.reroll)
    result = result + v

    if not seen_1d20 and part.dice_n == 1 and part.sides_n == 20 then
      seen_1d20 = true
      if v == 20 then
        crit_status = "nat_20"
      elseif v == 1 then
        crit_status = "nat_1"
      end
    end

    if v < 0 then
      repr = repr.." - "
    elseif i > 1 then
      repr = repr.." + "
    end
    repr = repr..math.abs(v)
    if part.advantage ~= 0 then
      repr = repr..(part.advantage > 0 and ADVANTAGE_CHAR or DISADVANTAGE_CHAR)
    end
    if rerolled then
      repr = repr.."🗘"
    end

    if part.comment or part.sides_n ~= 1 then
      repr = repr.." ("
      if part.sides_n ~= 1 then
        if part.dice_n ~= 1 then
          repr = repr..part.dice_n
        end
        repr = repr.."d"..part.sides_n
        if part.comment then
          repr = repr..", "
        end
      end
      if part.comment then
        repr = repr..part.comment
      end
      repr = repr..")"
    end
  end

  Log.debug("%s = %s", repr, result)

  return result, crit_status
end

--- @return integer
methods.max = function(self)
  local result = 0
  for _, dice in ipairs(self.parts) do
    result = result + dice.sides_n * dice.dice_n
  end
  return result
end

--- @return integer
methods.min = function(self)
  local result = 0
  for _, dice in ipairs(self.parts) do
    result = result + 1 * dice.dice_n
  end
  return result
end

--- @param value integer
--- @return d.roll
methods.shift_advantage = function(self, value)
  for _, part in ipairs(self.parts) do
    if part.sides_n ~= 1 then
      part.advantage = part.advantage + value
    end
  end
  return self
end

--- @param ... integer
methods.assign_reroll = function(self, ...)
  local changed = false
  for i = 1, select("#", ...) do
    local to_reroll = select(i, ...)
    if not table_contains(self.reroll, to_reroll) then
      table.insert(self.reroll, to_reroll)
      changed = true
    end
  end
  if changed then table.sort(self.reroll) end
  return self
end

--- @return d.roll
methods.copy = function(self)
  local result = setmetatable({
    parts = table_new(#self.parts, 0),
    reroll = {unpack(self.reroll)},
  }, d.mt)

  for i, dice in ipairs(self.parts) do
    result.parts[i] = dice_copy(dice)
  end

  return result
end

return d
