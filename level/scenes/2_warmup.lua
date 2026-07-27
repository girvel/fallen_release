local on_solids = require("level.palette.on_solids")
local items = require("level.palette.items")
local item = require("engine.tech.item")
local cutscene = require("engine.tech.cutscene")
local api = require("engine.tech.api")


return {
  loc_201 = cutscene.make {
    enabled = true,

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

  loc_202 = cutscene.make {
    enabled = true,

    _condition = function(self, dt, ch, ps)
      return State.player.position == ps.beds_check
    end,

    _run = function(self, ch, ps, sp)
      api.popup("Кровати плохо заправлены, будто это делали в одно движение.")
    end,
  },

  loc_204 = cutscene.make {
    enabled = true,

    _condition = function(self, dt, ch, ps)
      return State.player.position == ps.world_map_message
    end,

    _run = function(self, ch, ps, sp)
      api.popup("На стене висит старая мировая карта; тяжело различить хоть какой-то текст или даже очертания границ.")
    end,
  },

  loc_205 = cutscene.make {
    enabled = true,

    _condition = function(self, dt, ch, ps)
      return State.player.position == ps.scratched_table_message
    end,

    _run = function(self, ch, ps, sp)
      State.player:rotate(Vector.up)
      api.popup_check("investigation", 10,
        "Когда ты прищуриваешься, хаотичный узор из царапин на столе начинает напоминать тропический остров с пальмами, солнцем и счастливой семьей.",
        "Какой-то психопат порядочно поиздевался над столом."
      )
    end,
  },

  loc_206 = cutscene.make {
    enabled = true,

    _condition = function(self, dt, ch, ps)
      return State.player.position == ps.empty_dorm_message
    end,

    _run = function(self, ch, ps, sp)
      api.popup("Толстый слой пыли, отсутствие матраса и постельного белья. В этой комнате никто не живёт, очень давно.")
    end,
  },

  loc_207 = cutscene.make {
    enabled = true,

    _condition = function(self, dt, ch, ps)
      return api.distance(State.player, ps.sign_message) <= 2
    end,

    _run = function(self, ch, ps, sp)
      api.popup("Старый выцветший указатель. Налево — “столовая”, направо “-к*ю*-*омп*н*я”.", ps.sign_message)
    end,
  },

  loc_208 = cutscene.make {
    enabled = true,
    mode = "sequential",
    screenplay = "assets/screenplay/200_pipe.ms",
    characters = {
      player = {},
      colored_pipe = {},
    },

    _condition = function(self, dt, ch, ps)
      return ch.colored_pipe.was_interacted_by == State.player
    end,

    _run = function(self, ch, ps, sp)
      local n

      sp:lines()
      n = sp:start_single_option()
        if n ~= 1 then return end
        State.runner:remove(self)
        ch.colored_pipe.interact = nil
      sp:finish_single_option()

      n = State.player:ability_check("dex", 12) and 1 or 2
      sp:start_single_branch(n)
        if n == 1 then
          sp:lines()
          item.give(State.player, items.knife())
          sp:lines()
        else
          sp:lines()
          on_solids.fs.burst(ch.colored_pipe.position)
          sp:lines()
        end
      sp:finish_single_branch()
    end,
  },
}
