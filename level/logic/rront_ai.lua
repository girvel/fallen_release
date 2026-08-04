local api = require("engine.tech.api")
local combat = require("engine.mech.ais.combat")
local rront_ai = {}

--- @class rront_ai
--- @field combat_module combat_ai
local methods = {}
rront_ai.mt = {__index = methods}

--- @return rront_ai
rront_ai.new = function()
  return setmetatable({
    combat_module = combat.new(),
  }, rront_ai.mt)
end

methods.init = function(self, entity)
  self.combat_module:init(entity)
end

methods.deinit = function(self, entity)
  self.combat_module:deinit(entity)
end

methods.control = function(self, entity)
  if not State.combat then return end

  if State.hostility:get(entity, State.player) == "enemy" then
    return self.combat_module:control(entity)
  end

  api.travel(entity, State.level.positions.detective_exit)
end

methods.observe = function(self, entity, dt)
  if State.combat and not State:in_combat(entity) and api.is_visible(entity) then
    State:start_combat({entity})
  end
  return self.combat_module:observe(entity, dt)
end

Ldump.mark(rront_ai, {mt = "const"}, ...)
return rront_ai
