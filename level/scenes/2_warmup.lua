local cutscene = require("engine.tech.cutscene")
local api = require("engine.tech.api")


return {
  loc_201 = cutscene.make {
    enabled = true,
    characters = {},

    _condition = function(self, dt, ch, ps)
      return State.player.position == ps.leaky_vent_check
    end,

    _run = function(self, ch, ps, sp)
      api.popup_check("investigation", 10,
        "Темные пятна на стенах и потолке могут указывать на проблемы с вентиляцией и серьезные утечки воды.",
        "Тёмные пятна на полу и потолке складываются в гротескные узоры."
      )
    end,
  },
}
