local async = require("engine.tech.async")
local api = require("engine.tech.api")
local items = require("level.palette.items")
local item = require("engine.tech.item")
local combat = require("engine.mech.ais.combat")
local screenplay = require("engine.tech.screenplay")


local janitor_ai = {}

--- @class janitor_ai: ai_strict
--- @field combat_module combat_ai
--- @field current_line integer
--- @field bucket entity?
local methods = {}
janitor_ai.mt = {__index = methods}

--- @return janitor_ai
janitor_ai.new = function()
  return setmetatable({
    combat_module = combat.new(),
    current_line = 0,
  }, janitor_ai.mt)
end

methods.init = function(self, entity)
  Table.assert_fields(entity, {"faction"})
  self.combat_module:init(entity)
end

methods.deinit = function(self, entity)
  self.combat_module:deinit(entity)
end

local LINES do
  local sp = screenplay.new("assets/screenplay/468_janitor.ms", {})
  LINES = sp:literal():split("\n")
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

    if not State:exists(self.bucket) then
      entity:rotate(bucket_direction)
      self.current_line = self.current_line + 1
      State.model.popups = {}
      api.popup(LINES[self.current_line], entity)

      async.sleep(.2)
      if self.current_line == #LINES then
        State.hostility:set(entity.faction, "player", "enemy")
        return
      end

      State:remove(State.grids.on_tiles[bucket_position])
      bucket_position = State.grids.solids:find_free_position(entity.position, 1)
      if not bucket_position then break end
      self.bucket = State:add_at(solids.bucket(), bucket_position, "solids")
    end
  end

  local mark = State.grids.marks[entity.position]
  if mark then
    State:remove(mark)
  end

  -- 4. Pick up the bucket --
  local e = State.grids.solids[bucket_position] or State.grids.on_tiles[bucket_position]
  if e then State:remove(e) end

  item.give(entity, items.bucket())
end

methods.observe = function(self, entity, dt)
  return self.combat_module:observe(entity, dt)
end

Ldump.mark(janitor_ai, {mt = "const"}, ...)
return janitor_ai
