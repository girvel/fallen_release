local gear = require("engine.mech.gear")
local item = require("engine.tech.item")


--- @class palette.items: mech.items
local items = {}
Table.extend(items, require("engine.mech.items"))

items.gas_key = function()
  local e = {
    name = "Газовый ключ",
    codename = "gas_key",
    damage_roll = D(4),
    bonus = 1,
    tags = {
      light = true,
    },
    slot = "hands",
  }
  item.mix_in(e, "assets/animations/gas_key")
  return e
end

items.yellow_gloves = function()
  local e = {
    name = "Огнеупорные перчатки",
    codename = "yellow_gloves",
    slot = "gloves",
  }
  item.mix_in(e, "assets/animations/yellow_gloves")
  return e
end

items.coal = function()
  local e = {
    name = "Уголь",
    codename = "coal",
    slot = "bag",
    boring_flag = true,
  }
  item.mix_in(e, "assets/animations/coal")
  return e
end

items.large_valve = function()
  local e = {
    name = "большой вентиль",
    codename = "large_valve",
    damage_roll = D(2),
    tags = {},
    slot = "offhand",
  }
  item.mix_in(e, "assets/animations/large_valve")
  return e
end

items.flask = function()
  local e = {
    name = "фляга",
    codename = "flask",
    slot = "right_pocket",
  }
  item.mix_in(e, "assets/animations/flask")
  return e
end

items.protective_robe = function()
  local e = {
    name = "защитная роба",
    codename = "protective_robe",
    slot = "body",
    perks = {
      gear.heavy_armor,
    },
  }
  item.mix_in(e, "assets/animations/protective_robe")
  return e
end

items.bucket = function()
  local e = {
    name = "ведро",
    codename = "bucket",
    slot = "offhand",
    no_drop_flag = true,
  }
  item.mix_in(e, "assets/animations/bucket")
  return e
end

items.furry_head = function()
  local e = {
    codename = "furry_head",
    slot = "head",
    no_drop_flag = true,
  }
  item.mix_in(e, "assets/animations/furry_head")
  return e
end

items.mop = function()
  local e = {
    codename = "mop",
    name = "швабра",
    damage_roll = D(6),
    tags = {
      heavy = true,
      versatile = true,
    },
    slot = "hands",
  }
  item.mix_in(e, "assets/animations/mop")
  return e
end

Ldump.mark(items, {}, ...)
return items
