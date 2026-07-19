local humanoid = require("engine.mech.humanoid")
local player_base = require("engine.state.player.base")
local abilities = require("engine.mech.abilities")


local solids = {}

----------------------------------------------------------------------------------------------------
-- [SECTION] Entities
----------------------------------------------------------------------------------------------------

--- @class player: player_base

solids.player = function()
  local result = {
    name = "Протагонист",
    base_abilities = abilities.new(8, 8, 8, 8, 8, 8),
    level = 0,
    faction = "player",
  }
  player_base.mix_in(result)
  humanoid.mix_in(result)
  return result
end

return solids
