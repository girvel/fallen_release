local async = require("engine.tech.async")
local api = require("engine.tech.api")
local items = require("level.palette.items")
local item = require("engine.tech.item")
local combat = require("engine.mech.ais.combat")


local janitor_ai = {}

--- @class janitor_ai: ai_strict
--- @field combat_module combat_ai
--- @field bucket entity?
local methods = {}
janitor_ai.mt = {__index = methods}

--- @return janitor_ai
janitor_ai.new = function()
  return setmetatable({
    combat_module = combat.new(),
  }, janitor_ai.mt)
end

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

  -- 0. Reset state, may happen after reloading the game --
  if not entity.inventory.offhand then
    item.give(entity, items.bucket())
  end

  if self.bucket then
    State:remove(self.bucket)
    self.bucket = nil
  end

  -- 1. Go to a new place --
  do
    local destination
    local TRAVEL_R = 8
    for dy = -TRAVEL_R, TRAVEL_R do
      for dx = -TRAVEL_R, TRAVEL_R do
        destination = entity.position + V(dx, dy)
        local mark = State.grids.marks:slow_get(destination)
        if mark and api.build_path(entity.position, destination) then
          goto follow_path
        end
      end
    end

    for _ = 1, 10 do
      destination = entity.position + V(
        math.random(-TRAVEL_R, TRAVEL_R),
        math.random(-TRAVEL_R, TRAVEL_R)
      )

      local path = api.build_path(entity.position, destination)
      if path and #path > 2 then
        goto follow_path
      end
    end

    do return end
    ::follow_path::
    api.travel_persistent(entity, destination)
  end

  -- 2. Place the bucket --
  local bucket_position, bucket_direction
  for _, dir in ipairs(Vector.directions) do
    bucket_position = entity.position + dir
    if not State.grids.solids:slow_get(bucket_position) then
      bucket_direction = dir
      goto position_found
    end
  end
  do return end

  ::position_found::
  State:remove(entity.inventory.offhand)
  entity.inventory.offhand = nil
  local solids = require("level.palette.solids")
  self.bucket = State:add_at(solids.bucket(), bucket_position, "solids")

  -- 3. Mop the floor --
  local washing_direction = Random.item(Table.remove({Vector.up, Vector.down}, bucket_direction))
  entity:rotate(washing_direction)
  for _ = 1, math.random(5, 10) do
    entity:animate("hand_attack")
    async.sleep(.8)

    -- NEXT fix the bucket
  end

  local mark = State.grids.marks[entity.position]
  if mark then
    State:remove(mark)
  end
end

methods.observe = function(self, entity, dt)
  return self.combat_module:observe(entity, dt)
end

Ldump.mark(janitor_ai, {mt = "const"}, ...)
return janitor_ai
