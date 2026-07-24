local api = require("engine.tech.api")
local items = require("level.palette.items")
local item = require("engine.tech.item")
local async = require("engine.tech.async")
local combat = require("engine.mech.ais.combat")


local hauler_ai = {}

--- @class hauler_ai
--- @field point_i integer
--- @field combat_module combat_ai
local methods = {}
hauler_ai.mt = {__index = methods}

--- @return hauler_ai
hauler_ai.new = function()
  return setmetatable({
    point_i = 1,
    combat_module = combat.new(),
  }, hauler_ai.mt)
end

local travel_points = {"coal_pickup", "coal_dropoff"}

methods.init = function(self, entity)
  self.combat_module:init(entity)
end

methods.deinit = function(self, entity)
  self.combat_module:deinit(entity)
end

methods.control = function(self, entity)
  if State.hostility:get(entity, State.player) == "enemy" then
    return self.combat_module:control(entity)
  end

  if entity.position == State.level.positions[travel_points[self.point_i]] then
    async.sleep(3)
    self.point_i = 3 - self.point_i
    if self.point_i == 1 then
      State:remove(entity.inventory.bag)
      entity.inventory.bag = nil
    else
      item.give(entity, State:add(items.coal()))
    end
  end

  api.travel(entity, State.level.positions[travel_points[self.point_i]])
end

methods.observe = function(self, entity, dt)
  return self.combat_module:observe(entity, dt)
end

Ldump.mark(hauler_ai, {mt = "const"}, ...)
return hauler_ai
