local api = require("engine.tech.api")
local health = require("engine.mech.health")
local conditions = {}

--- @class condition
--- @field codename string
--- @field life_time integer duration in seconds

conditions.blinded = function()
  return {
    life_time = 6,
    codename = "blinded",

    modify_attack_roll = function(self, entity, roll, slot)
      return roll:set("disadvantage")
    end,

    modify_incoming_attack_roll = function(self, entity, roll, source)
      return roll:set("advantage")
    end,
  }
end

conditions.disengaged = function()
  return {
    codename = "disengaged",
    life_time = 6,

    modify_opportunity_attack_trigger = function(self, entity, triggered)
      return false
    end,
  }
end

--- @param life_time number
--- @param mod? ability
--- @param dc? integer
conditions.paralyzed = function(life_time, mod, dc)
  assert((mod == nil) == (dc == nil))
  return {
    codename = "paralyzed",
    life_time = life_time,
    mod = mod,
    dc = dc,

    -- TODO autofail dex/str saves

    move_start = function(self, entity)
      if self.mod and entity:saving_throw(self.mod, self.dc) then
        return true
      end
    end,

    modify_activation = function(self, entity, value, action)
      return false
    end,

    modify_incoming_attack_roll = function(self, entity, roll)
      return roll:set("advantage")
    end,

    modify_incoming_is_critical = function(self, entity, value, source)
      if api.distance(entity, source) == 1 then
        return true
      end
      return value
    end,
  }
end

--- @param damage integer
--- @param source entity
conditions.poisoned = function(damage, source)
  return {
    life_time = damage * 6,
    codename = "poisoned",
    _t = 0,
    update = function(self, entity, dt)
      local next_t = self._t + dt
      local d = math.floor(next_t / 6) - math.floor(self._t / 6)
      if d > 0 then
        health.damage(entity, d, source)
      end
      self._t = next_t
    end,
  }
end

Ldump.mark(conditions, {}, ...)
return conditions
