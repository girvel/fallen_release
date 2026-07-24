local humanoid = require("engine.mech.humanoid")
local item = require("engine.tech.item")
local sprite = require("engine.tech.sprite")
local mark = require("engine.tech.mark")
local animated = require("engine.tech.animated")
local creature = require("engine.mech.creature")
local combat_ai = require("engine.mech.ais.combat")
local abilities = require("engine.mech.abilities")


--- @class mech.monsters
local monsters = {}

local bones_sprites = sprite.collection("engine/assets/sprites/bones.png")
local add_bones = mark(function()
  return {
    codename = "bones",
    boring_flag = true,
    sprite = Random.item(bones_sprites),
  }
end)

local skeleton_base = function()
  local e = {
    name = "скелет",
    base_abilities = abilities.new(10, 14, 15, 6, 8, 5),
    armor = 13,
    level = 1,
    ai = combat_ai.new({follow_range = 30}),
    faction = "predators",
    on_death = add_bones,
    _is_a_skeleton = true,
    blind_sight_flag = true,
  }
  animated.mix_in(e, "engine/assets/animations/skeleton")
  return e
end

monsters.skeleton_heavy = function()
  local e = skeleton_base()
  e.codename = "skeleton_heavy"
  e.max_hp = 20
  e.inventory = {
    -- TODO give him a weapon
    -- hand = items.axe(),
  }
  creature.mix_in(e)
  return e
end

monsters.bat = function()
  local e = {
    name = "Летучая мышь",
    codename = "bat",
    base_abilities = abilities.new(6, 15, 8, 2, 12, 4),
    level = 1,
    ai = combat_ai.new(),
    speed = 8,
    max_hp = 1,
    faction = "predators",
    inventory = {
      hand = item.natural_weapon(D.new({}, 3)),
    },
    on_death = humanoid.add_blood_mark,
    blind_sight_flag = true,
    no_sound_flag = true,
  }
  animated.mix_in(e, "engine/assets/animations/bat/")
  creature.mix_in(e)
  return e
end

Ldump.mark(monsters, {}, ...)
return monsters
