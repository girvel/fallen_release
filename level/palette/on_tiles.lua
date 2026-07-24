local factoring = require("engine.tech.factoring")
local animated = require("engine.tech.animated")


local on_tiles = {}

----------------------------------------------------------------------------------------------------
-- [SECTION] Atlas
----------------------------------------------------------------------------------------------------

on_tiles.ATLAS_IMAGE = love.graphics.newImage("assets/atlases/on_tiles.png")
local packer = factoring.packer(on_tiles.ATLAS_IMAGE)

packer.offset = 0
for _, tuple in ipairs {
  {1, "toilet"},
  {2, "magazine"},
  {3, "blood"},
  {4, "dirt"},
  {5, "bucket"},
  {9, "mushroom"},
  {10, "mushroom"},
  {11, "mushroom"},
  {17, "bones"},
  {18, "bones"},
  {19, "bones"},
  {19, "bone_meal"},
  {20, "bone_meal"},
} do
  local index, codename = unpack(
    tuple --[=[@as [integer, string]]=]
  )
  local i, this_sprite = packer:geti(index)
  on_tiles[i] = function()
    return {
      boring_flag = true,
      codename = codename,
      sprite = this_sprite,
    }
  end
end

----------------------------------------------------------------------------------------------------
-- [SECTION] Entities
----------------------------------------------------------------------------------------------------

local adjust_rate = function(self)
  self.animation.fps = State.level.water_speed
end

for _, dirname in ipairs {"left", "right"} do
  local codename = "wave_"..dirname
  on_tiles[codename] = function()
    local e = {
      codename = codename,
      on_add = adjust_rate,
    }
    animated.mix_in(e, "assets/animations/"..codename, "no_atlas")
    return e
  end
end

Ldump.mark(on_tiles, {}, ...)
return on_tiles
