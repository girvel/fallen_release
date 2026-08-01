local stages = require("level.logic.stages")
local api = require("engine.tech.api")
local cutscene = require("engine.tech.cutscene")


return {
  _300_black_door = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/300_black_door.ms",

    _condition = function(self, dt, ch, ps)
      return not State:exists(State.level.entities.detective_door)
    end,

    _run = function(self, ch, ps, sp)
      api.order(sp:literal())
      State.rails:set_quest("detective", stages.detective._0020_investigate)
    end,
  },
}
