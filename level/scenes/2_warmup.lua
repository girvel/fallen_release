local interactive = require("engine.tech.interactive")
local async = require("engine.tech.async")
local health = require("engine.mech.health")
local shaders = require("level.shaders")
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

  loc_209 = cutscene.make {
    enabled = true,
    characters = {
      player = {},
    },

    _condition = function(self, dt, ch, ps)
      return State.player.position == ps.mouse_check
    end,

    _run = function(self, ch, ps, sp)
      api.line(nil, "Здесь повесилась мышь. Забавно.")
      api.popup_check("nature", 14,
        "Животные ощущают наш мир лучше, чем люди. Мышь, должно быть, предчувствовала что-то ужасное. Может, мне тоже начать бояться?",
        "У меня нет объяснений этому явлению."
      )
    end,
  },

  _210_latrine_warning = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/210_latrine_warning.ms",
    characters = {
      player = {},
    },

    _condition = function(self, dt, ch, ps)
      return State.player.position == ps.exit_latrine
    end,

    _run = function(self, ch, ps, sp)
      sp:lines()
    end,
  },

  _211_latrine_enter = cutscene.make {
    enabled = true,
    mode = "sequential",
    screenplay = "assets/screenplay/211_latrine_enter.ms",

    _condition = function(self, dt, ch, ps)
      return State.player.position == ps.enter_latrine
        and not State.rails.in_latrine
    end,

    _first_time = true,
    _run = function(self, ch, ps, sp)
      State.rails.in_latrine = true
      State.runner:cancel("_212_latrine_exit", true)

      if self._first_time then
        self._first_time = false
        State.rails.tolerates_latrine = State.player:saving_throw("con", 14)
        api.lock(State.player)
          sp:start_single_branch(State.rails.tolerates_latrine and 1 or 2)
            sp:lines()
          sp:finish_single_branch()
        api.unlock(State.player)
      end

      if State.rails.tolerates_latrine then
        State.rails.player_last_fov = State.player.fov_r
        State.player.fov_r = 1
      else
        State.shader = shaders.latrine
      end
    end,
  },

  _212_latrine_exit = cutscene.make {
    enabled = true,
    mode = "sequential",
    screenplay = "assets/screenplay/212_latrine_exit.ms",

    _condition = function(self, dt, ch, ps)
      return State.player.position == ps.exit_latrine
        and State.rails.in_latrine
    end,

    _first_time = true,
    _run = function(self, ch, ps, sp)
      State.rails.in_latrine = false
      State.runner:cancel("_211_latrine_enter")

      if State.rails.tolerates_latrine then
        State.player.fov_r = assert(State.rails.player_last_fov)
        State.rails.player_last_fov = nil
      else
        if self._first_time then
          self._first_time = false
          api.lock(State.player)
            sp:lines()
            health.damage(State.player, 1)
            sp:lines()
          api.unlock(State.player)
        else
          health.damage(State.player, 1)
        end

        async.sleep(10)
        State.shader = nil
      end
    end,

    _on_cancel = function()
      State.shader = nil
    end,
  },

  _213_dirty_magazine = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/213_dirty_magazine.ms",
    characters = {
      player = {},
      dirty_magazine = {},
    },

    _on_add = function(self, ch, ps)
      Log.traces(123)
      interactive.mix_in(ch.dirty_magazine)
      item.set_cue(ch.dirty_magazine, "highlight", true)
      ch.dirty_magazine.name = "Яркий журнал"
    end,

    _condition = function(self, dt, ch, ps)
      return ch.dirty_magazine.was_interacted_by == State.player
    end,

    _run = function(self, ch, ps, sp)
      ch.dirty_magazine.interact = nil
      sp:lines()
      sp:start_single_branch(State.player:ability_check("religion", 8) and 1 or 2)
        sp:lines()
      sp:finish_single_branch()
    end,
  },
}
