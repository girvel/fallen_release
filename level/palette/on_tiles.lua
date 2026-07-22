local animated = require("engine.tech.animated")


local on_tiles = {}

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
