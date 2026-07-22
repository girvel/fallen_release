local animated = require("engine.tech.animated")
--- @class level: level_base
--- @field water_speed integer

--- @type level_definition
return {
  ldtk_path = "level/ship.ldtk",
  palette = Table.do_folder("level/palette"),
  rails_new = require("level.rails").new,
  bg_new = function()
    local e = {
      codename = "background",
      boring_flag = true,
    }
    animated.mix_in(e, "assets/animations/water", "no_atlas")
    return e
  end,
  level_mix_in = function(base)
    base.water_speed = 5
  end,
}
