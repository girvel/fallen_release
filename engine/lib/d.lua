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

--- @class d.die
--- @field sides_n integer
--- @field advantage integer
--- @field comment string?
local die_methods = {}
d.die_mt = {__index = die_methods}

--- @param sides_n integer
--- @param comment string?
d.die_new = function(sides_n, comment)
  assert(sides_n > 0)
  return setmetatable({
    sides_n = sides_n,
    advantage = 0,
    comment = comment,
  }, d.die_mt)
end

local ADVANTAGE_CHAR = "↑"
local DISADVANTAGE_CHAR = "↓"

d.die_mt.__tostring = function(self)
  local result = "d"..self.sides_n

  if self.advantage > 0 then
    result = result..ADVANTAGE_CHAR
  elseif self.advantage < 0 then
    result = result..DISADVANTAGE_CHAR
  end

  if self.comment then
    result = result.." ("..self.comment..")"
  end
  return result
end

--- @return integer
die_methods.roll = function(self)
  local result = math.random(self.sides_n)
  if self.advantage > 0 then
    result = math.max(result, math.random(self.sides_n))
  elseif self.advantage < 0 then
    result = math.min(result, math.random(self.sides_n))
  end
  return result
end

--- @return d.die
die_methods.copy = function(self)
  return setmetatable({
    sides_n = self.sides_n,
    advantage = self.advantage,
    comment = self.comment,
  }, d.die_mt)
end

----------------------------------------------------------------------------------------------------
-- [SECTION] Dice
----------------------------------------------------------------------------------------------------

--- @class d.bonus
--- @field value integer
--- @field comment string?

--- @class d.roll
--- @field dice d.die[]
--- @field bonuses d.bonus[]
--- @field reroll integer[]
--- @operator add(d.roll): d.roll
--- @operator add(integer): d.roll
--- @operator sub(integer): d.roll
--- @operator mul(integer): d.roll
local methods = {}
d.mt = {__index = methods}

--- @param ... d.die
d.new = function(...)
  return setmetatable({
    dice = {...},
    bonuses = {},
    reroll = {},
  }, d.mt)
end

module_mt.__call = function(_, sides_n)
  return d.new(d.die_new(sides_n))
end

--- @param value integer
--- @param comment string?
--- @return d.roll
methods.add_bonus = function(self, value, comment)
  table.insert(self.bonuses, {value = value, comment = comment})
  return self
end

--- @param sides_n integer
--- @param comment string?
--- @return d.roll
methods.add_die = function(self, sides_n, comment)
  table.insert(self.dice, d.die_new(sides_n, comment))
  return self
end

--- @param self d.roll
--- @deprecated
d.mt.__add = function(self, other)
  if type(other) == "number" then
    return self:copy():add_bonus(other)
  end

  if type(other) == "table" then
    return self:copy():add_die(other)
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

  local result = setmetatable({
    dice = table_new(#self.dice * other, 0),
    bonuses = table_new(#self.bonuses * other, 0),
    reroll = {unpack(self.reroll)},
  }, d.mt)

  for _, die in ipairs(self.dice) do
    for _ = 1, other do
      table.insert(result.dice, die:copy())
    end
  end

  for _, bonus in ipairs(self.bonuses) do
    for _ = 1, other do
      table.insert(result.bonuses, {
        value = bonus.value,
        comment = bonus.comment,
      })
    end
  end

  return self
end

-- NEXT #self.reroll > 0 and ("🗘(%s)"):format(table.concat(self.reroll, ",")) or ""

--- @param self d.roll
d.mt.__tostring = function(self)
  local result = ""
  for i, die in ipairs(self.dice) do
    if i > 1 then result = result.." + " end
    result = result..tostring(die)
  end

  for i, bonus in ipairs(self.bonuses) do
    if bonus.value < 0 then
      result = result.." - "
    elseif i > 1 or #self.dice > 0 then
      result = result.." + "
    end
    result = result..math.abs(bonus.value)
    if bonus.comment then
      result = result.." ("..bonus.comment..")"
    end
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

--- @return integer
methods.roll = function(self)
  local result = 0
  local repr = ""
  for i, die in ipairs(self.dice) do
    local v = die:roll()
    local rerolled = table_contains(self.reroll, v)
    if rerolled then
      v = die:roll()
    end
    result = result + v

    if v < 0 then
      repr = repr.." - "
    elseif i > 1 then
      repr = repr.." + "
    end
    repr = repr..math.abs(v)
    if rerolled then
      repr = repr.."🗘"
    end
    if die.comment then
      repr = repr.." ("..die.comment..")"
    end
  end

  for i, bonus in ipairs(self.bonuses) do
    result = result + bonus.value
    if bonus.value < 0 then
      repr = repr.." - "
    elseif i > 1 or #self.dice > 0 then
      repr = repr.." + "
    end
    repr = repr..math.abs(bonus.value)
    if bonus.comment then
      repr = repr.." ("..bonus.comment..")"
    end
  end

  Log.debug("%s = %s", repr, result)

  return result
end

--- @return integer
methods.max = function(self)
  local result = 0
  for _, die in ipairs(self.dice) do
    result = result + die.sides_n
  end
  for _, bonus in ipairs(self.bonuses) do
    result = result + bonus.value
  end
  return result
end

--- @return integer
methods.min = function(self)
  local result = #self.dice
  for _, bonus in ipairs(self.bonuses) do
    result = result + bonus.value
  end
  return result
end

--- @param value integer
--- @return d.roll
methods.shift_advantage = function(self, value)
  local found = false
  for _, die in ipairs(self.dice) do
    if die.sides_n == 20 then
      assert(not found, "Can not set advantage for a roll with multiple D20")
      found = true
      die.advantage = die.advantage + value
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
    dice = table_new(#self.dice, 0),
    bonuses = table_new(#self.bonuses, 0),
    reroll = {unpack(self.reroll)},
  }, d.mt)

  for i, die in ipairs(self.dice) do
    result.dice[i] = die:copy()
  end

  for i, bonus in ipairs(self.bonuses) do
    result.bonuses[i] = {
      value = bonus.value,
      comment = bonus.comment,
    }
  end

  return result
end

return d
