local factoring = require("engine.tech.factoring")
local tiles = {}

tiles.ATLAS_IMAGE = love.graphics.newImage("assets/atlases/tiles.png")
local packer = factoring.packer(tiles.ATLAS_IMAGE)
packer.offset = 0

local codenames = string.tokens [[
  walkway planks steel_bars steel_bars_damaged steel_floor steel_floor_damaged
]]

for index, codename in ipairs(codenames) do
  local i, this_sprite = packer:geti(index)
  tiles[i] = function()
    return {
      boring_flag = true,
      codename = codename,
      sprite = this_sprite,
    }
  end
end

return tiles
