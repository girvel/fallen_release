local interactive = require("engine.tech.interactive")
local api = require("engine.tech.api")
local ui = require("engine.tech.ui")
local combat_ai = require("engine.mech.ais.combat")
local races = require("engine.mech.races")
local animated = require("engine.tech.animated")
local level = require("engine.tech.level")
local animated = require("engine.tech.animated")
local creature = require("engine.mech.creature")
local perks = require("engine.mech.perks")
local on_solids = require("level.palette.on_solids")
local reflective = require("level.shaders.reflective")
local async = require("engine.tech.async")
local sound = require("engine.tech.sound")
local interactive = require("engine.tech.interactive")
local factoring = require("engine.tech.factoring")
local humanoid = require("engine.mech.humanoid")
local player_base = require("engine.state.player.base")
local abilities = require("engine.mech.abilities")


local solids = {fs = {}}

----------------------------------------------------------------------------------------------------
-- [SECTION] Atlas
----------------------------------------------------------------------------------------------------

solids.ATLAS_IMAGE = love.graphics.newImage("assets/atlases/solids.png")
local packer = factoring.packer(solids.ATLAS_IMAGE)

packer.offset = 0
for y = 1, 4 do
  for x = 1, 4 do
    if y == 4 and x <= 2 then goto continue end
    local i, this_sprite = packer:get(x, y)
    solids[i] = function()
      return {
        boring_flag = true,
        codename = "wall_steel",
        sprite = this_sprite,
      }
    end
    ::continue::
  end
end

for y = 1, 4 do
  for x = 5, 8 do
    if y == 4 and x <= 6 then goto continue end
    local i, this_sprite = packer:get(x, y)
    solids[i] = function()
      return {
        boring_flag = true,
        codename = "wall_steel_transparent",
        sprite = this_sprite,
        transparent_flag = true,
      }
    end
    ::continue::
  end
end

local make_open = function(factory, target_layer, soundname)
  local sounds = soundname and sound.multiple("assets/sounds/"..soundname.."/open", .8)
  return function(self)
    if self._locked then
      api.popup(5, self, "Закрыто.")
      return
    end

    local open_itself = function()
      State:remove(self)
      State:add_at(factory(), self.position, target_layer)
    end

    local _, scene = State.runner:run_task(function()
      if sounds then
        sounds:play_at(self.position)
      end
      async.sleep(.18)
      open_itself()
    end)
    scene.on_cancel = open_itself
  end
end

do
  local open = make_open(on_solids[25], "on_solids", false)
  local i, this_sprite = packer:geti(25)
  solids[i] = function(params)
    local e = {
      boring_flag = true,
      codename = "door",
      name = "дверь",
      sprite = this_sprite,
      _locked = params.locked,
    }
    interactive.mix_in(e, open)
    return e
  end
end

packer.offset = 32
for _, tuple in ipairs {
  {1, "locker", "шкафчик", "cabinet"},
  {9, "cabinet", "шкаф", "cabinet"},
  {13, "crate", "ящик", false},
  {15, "chest", "сундук", "chest"},
} do
  local index, codename, name, soundname = unpack(
    tuple --[=[@as [integer, string, string, string, boolean, string|false]]=]
  )

  local i_open, sprite_open = packer:geti(index + 1)
  solids[i_open] = function()
    return {
      boring_flag = true,
      transparent_flag = true,
      codename = codename,
      name = name,
      sprite = sprite_open,
    }
  end

  local open = make_open(solids[i_open], "solids", soundname)
  local i_closed, sprite_closed = packer:geti(index)
  solids[i_closed] = function()
    local e = {
      boring_flag = true,
      transparent_flag = true,
      codename = codename,
      name = name,
      sprite = sprite_closed,
    }
    interactive.mix_in(e, open)
    return e
  end
end

do
  local breaking_sound = sound.multiple("assets/sounds/door_breaking")
  local i, this_sprite = packer:get(2, 0)
  solids[i] = function()
    return {
      boring_flag = true,
      transparent_flag = true,
      codename = "breakable_door",
      name = "дверь",
      sprite = this_sprite,
      hp = 1,
      on_remove = function(self)
        State:add_at(on_solids[17](), self.position, "on_solids")
        breaking_sound:play_at(self.position)
      end,
      modify = creature.methods.modify,
      perks = {
        perks.toughness,
      },
      conditions = {},
      inventory = {},
    }
  end
end

do
  local i_broken, sprite_broken = packer:get(5, 1)
  solids[i_broken] = function()
    return {
      boring_flag = true,
      transparent_flag = true,
      codename = "panel",
      name = "приборная панель",
      sprite = sprite_broken,
    }
  end

  local breaking_sound = sound.multiple("assets/sounds/glass_breaking", .5)
  local i_intact, sprite_intact = packer:get(4, 1)
  solids[i_intact] = function()
    return {
      boring_flag = true,
      transparent_flag = true,
      codename = "panel",
      name = "приборная панель",
      sprite = sprite_intact,
      hp = 1,
      on_remove = function(self)
        State:add_at(solids[i_broken](), self.position, "solids")
        breaking_sound:play_at(self.position)
      end,
      shader = reflective(Vector.down),
    }
  end
end

do
  local i_broken, sprite_broken = packer:get(8, 3)
  solids[i_broken] = function()
    return {
      boring_flag = true,
      transparent_flag = true,
      codename = "bucket",
      name = "ведро",
      sprite = sprite_broken,
    }
  end

  local breaking_sound = sound.multiple("assets/sounds/bucket")
  local i_intact, sprite_intact = packer:get(7, 3)
  solids[i_intact] = function()
    return {
      boring_flag = true,
      transparent_flag = true,
      codename = "bucket",
      name = "ведро",
      sprite = sprite_intact,
      hp = 1,
      on_remove = function(self)
        State:add_at(solids[i_broken](), self.position, "solids")
        breaking_sound:play_at(self.position)
      end,
      shader = reflective(Vector.down),
    }
  end
end

for _, tuple in ipairs {
  {3, "locker_damaged"},
  {5, "panel_damaged"},
  {6, "panel"},
  {7, "panel"},
  {11, "cabinet_damaged"},
  {12, "fireplace"},
  {17, "cabinet"},
  {18, "cabinet"},
  {19, "cabinet"},
  {20, "cabinet"},
  {21, "cabinet"},
  {22, "cabinet"},
} do
  local index, codename = unpack(tuple --[=[@as [integer, string]]=])
  local i, this_sprite = packer:geti(index)
  solids[i] = function()
    return {
      boring_flag = true,
      transparent_flag = true,
      codename = codename,
      sprite = this_sprite,
    }
  end
end

packer.offset = 56
for x = 1, 4 do
  for y = 1, 3 do
    local codename = (x == 3 and y == 3) and "sink" or "countertop"
    local i, this_sprite = packer:get(x, y)
    solids[i] = function()
      return {
        boring_flag = true,
        transparent_flag = true,
        codename = codename,
        sprite = this_sprite,
      }
    end
  end
end

for x = 5, 8 do
  for y = 1, 3 do
    local codename = (5 <= x and x <= 8 and y == 3) and "bed" or "table"
    local i, this_sprite = packer:get(x, y)
    solids[i] = function()
      return {
        boring_flag = true,
        transparent_flag = true,
        codename = codename,
        sprite = this_sprite,
      }
    end
  end
end

packer.offset = 80
for _, tuple in ipairs {
  {1, "sofa"},
  {2, "sofa"},
  {3, "sofa"},
  {4, "stool"},
  {5, "loo"},
  {9, "coal"},
  {10, "coal"},
  {11, "coal"},
  {12, "coal"},
  {13, "cage", "клетка"},
  {14, "mirage_block", "блок миража"},
  {15, "stage"},
} do
  local index, codename, name = unpack(
    tuple --[=[@as [integer, string, string?]]=]
  )
  local i, this_sprite = packer:geti(index)
  solids[i] = function()
    return {
      boring_flag = true,
      transparent_flag = true,
      codename = codename,
      name = name,
      sprite = this_sprite,
    }
  end
end

packer.offset = 96
for x = 1, 5 do
  for y = 1, 4 do
    local i, this_sprite = packer:get(x, y)
    solids[i] = function()
      return {
        boring_flag = true,
        transparent_flag = true,
        codename = "pipe",
        sprite = this_sprite,
        shader = reflective(Vector.left),
      }
    end
    if x == 5 and y == 1 then break end
  end
end

do
  local i, this_sprite = packer:get(6, 1)
  solids[i] = function()
    local e = {
      boring_flag = true,
      transparent_flag = true,
      codename = "pipe",
      name = "необычная труба",
      sprite = this_sprite,
      shader = reflective(Vector.right),
    }
    interactive.mix_in(e)
    return e
  end
end

packer.offset = 104
for y = 1, 6 do
  for x = 5, 8 do
    if y == 2 and (x == 5 or x == 8) then goto continue end
    local i, this_sprite = packer:get(x, y)
    local shader = y == 6 and x > 5 and reflective(Vector.down) or nil
    solids[i] = function()
      return {
        boring_flag = true,
        transparent_flag = true,
        codename = "engine",
        name = "двигатель",
        sprite = this_sprite,
        shader = shader,
      }
    end

    ::continue::
  end
end

----------------------------------------------------------------------------------------------------
-- [SECTION] Entities
----------------------------------------------------------------------------------------------------

--- @class player: player_base
--- @field incapacitated boolean

solids.player = function()
  local result = {
    name = "Протагонист",
    base_abilities = abilities.new(8, 8, 8, 8, 8, 8),
    level = 0,
    faction = "player",
    incapacitated = false,
  }
  player_base.mix_in(result)
  humanoid.mix_in(result)
  return result
end

solids.mannequin = function()
  local e = {
    name = "манекен",
    codename = "mannequin",
    hp = 1000,
    armor = 5,
    transparent_flag = true,
    boring_flag = true,
    sounds = sound.multiple("assets/sounds/hits_body", 0.3),
  }
  animated.mix_in(e, "assets/animations/mannequin", "no_atlas")
  return e
end

local dreamer_races = {races.dwarf, races.human, races.half_elf, races.half_orc, races.halfling}

solids.dreamer = function(params)
  local e = {
    name = "...",
    codename = "dreamer",
    race = params.race or Random.item(dreamer_races),
    max_hp = 15,
    hp = params.blood and 6 or nil,
    base_abilities = abilities.new(12, 10, 10, 10, 10, 10),
    ai = params.faction and combat_ai.new(),
    faction = params.faction,
    inventory = params.inventory,
    level = 1,
  }
  creature.mix_in(e)
  humanoid.mix_in(e)
  return e
end

solids.fs.open = function(self)
  if self.grid_layer == "on_solids" or not self.animation.current:starts_with("idle") then
    return
  end
  self.interact = nil
  self:animate("open"):next(function()
    animated.change_pack(self, "assets/animations/"..self.codename.."/open", "no_atlas")
    level.change_grid_layer(self, "on_solids")
  end)
end

for _, postfix in ipairs {"", "c"} do
  for i = 1, 3 do
    local codename = "megadoor"..i..postfix
    local is_interactive = i == 3
    solids[codename] = function()  --- @diagnostic disable-line
      local result = {
        name = "шлюз",
        codename = codename,
        boring_flag = true,
        _locked = true,
      }

      animated.mix_in(result, "assets/animations/"..codename.."/closed", "no_atlas")
      if is_interactive then
        interactive.mix_in(result, function(self, other)
          if self._locked then
            api.popup(5, self, "Закрыто.")
            return
          end
          for d = 0, 2 do
            local e = State.grids.solids:slow_get(self.position + Vector.left * d)
            if e then solids.fs.open(e) end
          end
        end)
      end
      return result
    end
  end
end

return solids
