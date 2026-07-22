local item = require("engine.tech.item")
local animated = require("engine.tech.animated")


--- @class mech.weapons
local weapons = {}

weapons._arrow = function()
  local e = {
    codename = "arrow",
    boring_flag = true,
  }
  animated.mix_in(e, "engine/assets/animations/arrow")
  item.mix_min(e, "hand")
  return e
end

weapons.short_bow = function()
  local e = {
    name = "короткий лук",
    codename = "short_bow",
    damage_roll = D(6),
    tags = {
      two_handed = true,
      ranged = true,
    },
    slot = "offhand",
    projectile_factory = weapons._arrow,
  }
  item.mix_in(e, "engine/assets/animations/short_bow")
  return e
end

weapons.axe = function()
  local e = {
    name = "топорик",
    codename = "axe",
    damage_roll = D(6),
    tags = {},
    slot = "hands",
  }
  item.mix_in(e, "engine/assets/animations/axe")
  return e
end

weapons.knife = function()
  local e = {
    name = "кухонный нож",
    codename = "knife",
    damage_roll = D(4),
    tags = {
      finesse = true,
      light = true,
    },
    slot = "hands",
  }
  item.mix_in(e, "engine/assets/animations/knife")
  return e
end

weapons.pole = function()
  local e = {
    name = "двуручный шест",
    codename = "pole",
    damage_roll = D(6),
    bonus = -1,
    tags = {
      heavy = true,
      two_handed = true,
    },
    slot = "hands",
  }
  item.mix_in(e, "engine/assets/animations/pole")
  return e
end

weapons.lamp = function()
  local e = {
    name = "лампа",
    codename = "lamp",
    tags = {
      finesse = true,
      light = true,
    },
    slot = "hands",
    light_intensity = 0.5,
  }
  item.mix_in(e, "engine/assets/animations/lamp")
  return e
end

Ldump.mark(weapons, "const", ...)
return weapons
