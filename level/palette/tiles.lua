local factoring = require("engine.tech.factoring")
local tiles = {}

tiles.ATLAS_IMAGE = love.graphics.newImage("assets/atlases/tiles.png")
local packer = factoring.packer(tiles.ATLAS_IMAGE)
packer.offset = 0

for _, tuple in ipairs {
  {1, "walkway"},
  {2, "planks"},
  {3, "steel_bars"},
  {4, "steel_bars_damaged"},
  {9, "steel_floor"},
  {10, "steel_floor_damaged"},
  {11, "dirt"},
  {17, "planks_straight"},
  {18, "planks_straight"},
  {25, "planks_straight"},
  {26, "planks_straight"},
} do
  local index, codename = unpack(
    tuple --[=[@as [integer, string]]=]
  )
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
