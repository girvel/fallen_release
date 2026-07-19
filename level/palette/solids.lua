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
    local is_transparent = x == 4 and (y == 1 or y == 2)
    solids[i] = function()
      return {
        boring_flag = true,
        codename = "wall_steel",
        sprite = this_sprite,
        transparent_flag = is_transparent,
      }
    end
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
