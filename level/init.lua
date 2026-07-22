--- @class level: level_base
--- @field water_speed integer

--- @type level_definition
return {
  ldtk_path = "level/ship.ldtk",
  palette = Table.do_folder("level/palette"),
  rails_new = require("level.rails").new,
  level_mix_in = function(base)
    base.water_speed = 5
  end,
}
