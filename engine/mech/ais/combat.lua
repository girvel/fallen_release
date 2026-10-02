local ai = require("engine.tech.ai")
local async = require("engine.tech.async")
local api = require("engine.tech.api")
local tcod = require("engine.tech.tcod")
local animated = require("engine.tech.animated")
local actions = require("engine.mech.actions")


local combat_ai = {}

--- @alias combat_ai combat_ai_strict|table

--- @class combat_ai_strict: ai_strict
--- @field targeting ai_targeting
--- @field target entity?
--- @field starts_no_fights boolean
--- @field _hostility_subscription function
--- @field _vision_map tcod_map
local methods = {}
combat_ai.mt = {__index = methods}

--- @type ai_targeting
local DEFAULT_TARGETING = {
  scan_period = .5,
  scan_range = 10,
  support_range = 15,
  follow_range = 20,
  sane_traveling_distance = 30,  -- 2.5 turns
}

--- @param targeting? table
--- @param starts_no_fights? boolean
--- @return combat_ai
combat_ai.new = function(targeting, starts_no_fights)
  return setmetatable({
    targeting = Table.defaults(targeting, DEFAULT_TARGETING),
    starts_no_fights = starts_no_fights,
  }, combat_ai.mt)
end

--- @param entity entity
methods.init = function(self, entity)
  self._hostility_subscription = State.hostility:subscribe(function(attacker, target)
    if entity.hp <= 0 then return end
    if State.hostility:get(entity, attacker) == "ally" then return end

    if State.hostility:get(entity, target) == "ally"
      and (target.position - entity.position):abs2() <= self.targeting.support_range
    then
      State.hostility:set(entity.faction, attacker.faction, "enemy")
      if not State:in_combat(entity) then
        State:add(animated.fx("engine/assets/animations/aggression", entity.position))
        State:start_combat({entity, attacker})
      end
    end
  end)

  self._vision_map = tcod.map(State.grids.solids)
end

--- @param entity entity
methods.deinit = function(self, entity)
  State.hostility:unsubscribe(self._hostility_subscription)
  self._vision_map:free()
end

local get_speed = function() return #State.combat.list > 8 and 9 or 7 end

methods._target_criteria = function(self, entity, target)
  return State:exists(target)
    and State.hostility:get(entity, target) == "enemy"
    and api.distance(entity, target) <= self.targeting.follow_range
    and api.traveling_distance(entity, target) <= self.targeting.sane_traveling_distance
end

--- @param entity entity
methods._target_search = function(self, entity)
  if self:_target_criteria(self.target) then return end
  if self.target then
    Log.debug("Invalid target")
  else
    Log.debug("No target, searching...")
  end

  self.target = ai.find_target(entity, self.targeting.scan_range, self._vision_map)
  if self.target then
    Log.debug("Found a target %s at %s", Name.code(self.target), self.target.position)
    return
  end
  Log.debug("Direct search provided no result")

  for _, e in ipairs(State.combat.list) do
    if State.hostility:get(entity, e) == "ally"
      and e.ai
      and e.ai.target
      and api.traveling_distance(entity, e) <= self.targeting.sane_traveling_distance
    then
      Log.debug(
        "Ally %s's has target %s at %s, going there",
        Name.code(e), Name.code(e.ai.target), e.ai.target.position
      )
      api.travel(entity, e.position, true)
      break
    end
  end

  if not ai.sees_enemies(entity, self.targeting.scan_range, self._vision_map) then
    Log.debug("Can not find any target")
    State:remove_from_combat(entity)
  end

  do return end
end

--- @param entity entity
methods.control = function(self, entity)
  if not State.combat or State.level.locked_entities[State.player] then
    self.target = nil
    return
  end

  ai.heal(entity)
  self:_target_search(entity)
  if not self.target then return end

  local bow = entity.inventory.offhand
  if bow and bow.tags.ranged then
    ai.preserve_line_of_fire(entity, self.target, self._vision_map, get_speed())
    local bow_attack = actions.bow_attack(self.target)
    local did_shoot = false
    while bow_attack:act(entity) do
      Log.debug("Shooting...")
      async.sleep(.66)
      did_shoot = true
    end

    if not did_shoot then
      Log.debug("Did not shoot once")
    end
  else
    if api.distance(entity, self.target) > 1 then
      Log.debug("Traveling to the target...")
      api.travel(entity, self.target.position, true, get_speed())
    end
    Log.debug("Attacking the target...")
    api.attack(entity, self.target)
  end
end

--- @param entity entity
--- @param dt number
methods.observe = function(self, entity, dt)
  if State.level.locked_entities[State.player] or entity.hp <= 0 then return end
  if not Random.chance(dt / self.targeting.scan_period) then return end

  if State.combat and not State:in_combat(entity) then
    for _, e in ipairs(State.combat.list) do
      if State.hostility:get(entity, e) == "ally"
        and (entity.position - e.position):abs2() <= self.targeting.support_range
      then
        State:add(animated.fx("engine/assets/animations/aggression", entity.position))
        State:start_combat({entity})
      end
    end
  end

  if not self.starts_no_fights then
    local new_target = ai.find_target(entity, self.targeting.scan_range, self._vision_map)
    if new_target and not State:in_combat(new_target) then
      State:add(animated.fx("engine/assets/animations/aggression", entity.position))
      State:start_combat({new_target, entity})
    end
  end
end

Ldump.mark(combat_ai, {mt = {}}, ...)
return combat_ai
