local gear = require("engine.mech.gear")
local animated = require("engine.tech.animated")
local item = require("engine.tech.item")


--- @class mech.items
local items = {}

items._arrow = function()
  local e = {
    codename = "arrow",
    boring_flag = true,
  }
  animated.mix_in(e, "engine/assets/animations/arrow")
  item.mix_min(e, "hand")
  return e
end

items.short_bow = function()
  local e = {
    name = "короткий лук",
    codename = "short_bow",
    damage_roll = D(6),
    tags = {
      two_handed = true,
      ranged = true,
    },
    slot = "offhand",
    projectile_factory = items._arrow,
  }
  item.mix_in(e, "engine/assets/animations/short_bow")
  return e
end

items.axe = function()
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

items.knife = function()
  local e = {
    name = "кухонный нож",
    codename = "knife",
    damage_roll = D(2),
    bonus = 1,
    tags = {
      finesse = true,
      light = true,
    },
    slot = "hands",
  }
  item.mix_in(e, "engine/assets/animations/knife")
  return e
end

items.dagger = function()
  local e = {
    name = "кортик",
    codename = "dagger",
    damage_roll = D(4),
    tags = {
      finesse = true,
      light = true,
    },
    slot = "hands",
  }
  item.mix_in(e, "engine/assets/animations/dagger")
  return e
end

items.razor = function()
  local e = {
    name = "опасная бритва",
    codename = "razor",
    damage_roll = D(4),
    tags = {
      finesse = true,
      light = true,
    },
    slot = "hands",
  }
  item.mix_in(e, "engine/assets/animations/razor")
  return e
end

items.machete = function()
  local e = {
    name = "мачете",
    codename = "machete",
    damage_roll = D(6),
    tags = {},
    slot = "hands",
  }
  item.mix_in(e, "engine/assets/animations/machete")
  return e
end

items.mace = function()
  local e = {
    name = "булава",
    codename = "mace",
    damage_roll = D(8),
    tags = {light = true},
    slot = "hands",
  }
  item.mix_in(e, "engine/assets/animations/mace")
  return e
end

items.greatsword = function()
  local e = {
    name = "двуручный меч",
    codename = "greatsword",
    damage_roll = D(6) * 2,
    tags = {
      two_handed = true,
      heavy = true,
    },
    slot = "hands",
  }
  item.mix_in(e, "engine/assets/animations/greatsword")
  return e
end

items.pole = function()
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

items.shield = function()
  local e = {
    name = "щит",
    codename = "shield",
    slot = "offhand",
    perks = {gear.shield},
  }
  item.mix_in(e, "engine/assets/animations/shield")
  return e
end

items.small_shield = function()
  local e = {
    name = "баклер",
    codename = "small_shield",
    slot = "offhand",
    perks = {gear.weak_shield},
  }
  item.mix_in(e, "engine/assets/animations/small_shield")
  return e
end

items.lamp = function()
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

--- @alias hair_type "hair_short_1"|"hair_short_2"|"hair_short_3"|"hair_long"
--- @enum (key) hair_color
local hair_colors = {
  gray = Vector.hex("4f5a5c"),
  red = Vector.hex("e86c46"),
  brown = Vector.hex("544747"),
}

--- @param type hair_type
--- @param color hair_color|vector
items.hair = function(type, color)
  color = hair_colors[color] or color  --- @cast color vector
  local e = {
    anchor = "head"
  }
  item.mix_min(e, "hair")
  animated.mix_in(e, "engine/assets/animations/" .. type, "directional", color)
  return e
end

--- @param type "tatoo_snake"|"scar_cheek"|"scar_eye"
items.skin = function(type)
  local e = {
    codename = type,
    slot = "skin",
    anchor = "head",
  }
  item.mix_in(e, "engine/assets/animations/" .. type)
  return e
end

return items
