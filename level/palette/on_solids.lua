local sprite = require("engine.tech.sprite")
local reflective = require("level.shaders.reflective")
local factoring = require("engine.tech.factoring")


local on_solids = {}
on_solids.ATLAS_IMAGE = love.graphics.newImage("assets/atlases/on_solids.png")
local packer = factoring.packer(on_solids.ATLAS_IMAGE)

packer.offset = 0
do
  local i, this_sprite = packer:get(1, 1)
  on_solids[i] = function()
    return {
      boring_flag = true,
      perspective_flag = true,
      codename = "mirror",
      sprite = this_sprite,
      shader = reflective(Vector.down * 2),
    }
  end
end

do
  local i, this_sprite = packer:get(6, 3)
  on_solids[i] = function()
    return {
      boring_flag = true,
      codename = "son_mary_bottom",
      name = "Голова в банке",
      sprite = this_sprite,
      portrait = sprite.image("assets/portraits/son_mary.png"),
    }
  end
end

for _, tuple in ipairs {
  {2, "grime"},
  {3, "airway", true},
  {4, "map", true},
  {5, "sign"},
  {6, "window"},
  {7, "upper_bunk", true},
  {8, "cauldron", true},
  {9, "vines"},
  {10, "vines"},
  {11, "vines"},
  {12, "vines"},
  {13, "vines"},
  {14, "son_mary_top"},
  {15, "blood", true},
  {16, "cauldron", true},
  {17, "door_broken", true},
  {18, "vines"},
  {19, "vines"},
  {20, "vines"},
  {21, "vines"},
  {23, "helm"},
  {24, "inscription"},
  {25, "door_open"},
  {28, "vines"},
  {29, "vines"},
  {30, "note"},
  {36, "vines"},
  {37, "vines"},
  {41, "engine"},
  {42, "engine"},
  {43, "engine"},
  {44, "engine"},
  {49, "engine"},
  {50, "engine"},
  {51, "engine"},
  {57, "engine"},
  {58, "engine"},
  {59, "engine"},
} do
  local index, codename, perspective_flag = unpack(
    tuple --[=[@as [integer, string, true?]]=]
  )
  local i, this_sprite = packer:geti(index)
  on_solids[i] = function()
    return {
      boring_flag = true,
      perspective_flag = perspective_flag,
      codename = codename,
      sprite = this_sprite,
    }
  end
end

Ldump.mark(on_solids, {}, ...)
return on_solids
