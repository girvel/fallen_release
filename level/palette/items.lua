local interactive = require("engine.tech.interactive")
local animated = require("engine.tech.animated")
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
  e.on_interact = function(self, other)
    State.rails:get_valve()
  end
  return e
end

items.flask = function()
  local e = {
    name = "фляга",
    codename = "flask",
  }
  item.mix_min(e, "right_pocket")
  item.set_cue(e, "highlight", true)
  animated.mix_in(e, "assets/animations/flask")
  interactive.mix_in(e, function(self)
    State:remove(self)
    State.rails:alcohol_pick_up("flask")
  end)
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
    no_drop_flag = true,
  }
  item.mix_in(e, "assets/animations/protective_robe")
  return e
end

items.bucket = function()
  local e = {
    boring_flag = true,
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
