local async = require("engine.tech.async")
local sound = require("engine.tech.sound")
local interactive = require("engine.tech.interactive")
local factoring = require("engine.tech.factoring")
local humanoid = require("engine.mech.humanoid")
local player_base = require("engine.state.player.base")
local abilities = require("engine.mech.abilities")


local solids = {}

----------------------------------------------------------------------------------------------------
-- [SECTION] Atlas
----------------------------------------------------------------------------------------------------

solids.ATLAS_IMAGE = love.graphics.newImage("assets/atlases/solids.png")
local packer = factoring.packer(solids.ATLAS_IMAGE)

packer.offset = 0
for y = 1, 4 do
  for x = 1, 4 do
    local i, this_sprite = packer:get(x, y)
    solids[i] = function()
      return {
        boring_flag = true,
        codename = "wall_steel",
        sprite = this_sprite,
      }
    end
  end
end

for y = 5, 8 do
  for x = 1, 4 do
    local i, this_sprite = packer:get(x, y)
    solids[i] = function()
      return {
        boring_flag = true,
        codename = "wall_steel_transparent",
        sprite = this_sprite,
        transparent_flag = true,
      }
    end
  end
end

local make_open = function(factory, target_layer, soundname)
  local sounds = soundname and sound.multiple("assets/sounds/"..soundname.."/open", .8)
  return function(self)
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

packer.offset = 32
for _, tuple in ipairs {
  {1, "locker", "шкафчик", "cabinet"},
  {9, "cabinet", "шкаф", "cabinet"},
  {13, "crate", "ящик", false},
  {15, "chest", "сундук", "chest"},
} do
  local index, codename, name, soundname = unpack(
    tuple --[=[@as [integer, string, string, string|false]]=]
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
  local i_broken, sprite_broken = packer:get(5, 1)
  solids[i_broken] = function()
    return {
      boring_flag = true,
      transparent_flag = true,
      codename = "panel",
      name = "приборная панель",
      sprite = sprite_broken
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
    }
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

return solids
