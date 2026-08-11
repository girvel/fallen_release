local ai = require("engine.state.player.ai")
local action = require("engine.tech.action")
local creature = require "engine.mech.creature"


local base = {}

-- TODO maybe .hears, .speaks etc. should go to State.gui, which is a game state for Kernel.gui

--- @class player.base: entity_strict
--- @field fov_r integer
--- @field ai player_ai
--- @field creator_model table?
--- @field appearance_model table?
--- @field bag player.bag
--- @field souls_n integer

--- @class player.bag
--- @field money integer
--- @field alcohol integer
--- @field valve integer
--- @field sigs integer
--- @field amulet integer
--- @field bird_food integer
--- @field bird_remains integer

--- @param entity table
base.mix_in = function(entity)
  creature.mix_in(entity)
  entity.codename = "player"
  entity.player_flag = true
  entity.fov_r = 15
  entity.bag = {
    money = 0,
    alcohol = 0,
    valve = 0,
    sigs = 0,
    amulet = 0,
    bird_food = 0,
    bird_remains = 0,
  }
  entity.ai = ai.new()
  entity.immovable_flag = true
  entity.on_death = false
  entity.souls_n = entity.souls_n or 1
end

--- @type action
base.skip_turn = Table.extend({
  name = "Завершить ход",
  codename = "skip_turn",

  _is_available = function(self, entity)
    return State.combat and State.combat:get_current() == entity
  end,
  _act = function(self, entity)
    entity.ai.finish_turn = true
    return true
  end,
}, action.base)

Ldump.mark(base, {}, ...)
return base
