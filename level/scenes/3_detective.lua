local interactive = require("engine.tech.interactive")
local screenplay = require("engine.tech.screenplay")
local async = require("engine.tech.async")
local actions = require("engine.mech.actions")
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

  _302_half_elf = cutscene.make {
    boring_flag = true,
    enabled = true,
    mode = "sequential",
    screenplay = "assets/screenplay/302_half_elf.ms",
    characters = {
      engineer_1 = {},
    },

    _on_add = function(self, ch, ps)
      ch.engineer_1:rotate(Vector.down)
      ch.engineer_1:animate("holding", true, true)
    end,

    _condition_t = 5,
    _condition = function(self, dt, ch, ps)
      if ch.engineer_1.position ~= ps.engineer_1 then
        State.runner:remove(self)
        return false
      end

      self._condition_t = self._condition_t - dt
      if self._condition_t <= 0 then
        self._condition_t = Random.float(30, 40)
        return true
      end
      return false
    end,

    _run = function(self, ch, ps, sp)
      local choices = sp:literal():split("\n")
      local n = math.random(#choices)

      local suffix
      if n == 1 then
        suffix = ("%.2f"):format(Random.float(1.5, 2.7))
      elseif n == 2 then
        suffix = math.random(40, 80)
      elseif n == 3 then
        suffix = ("%.2f"):format(Random.float(2.6, 5.2))
      elseif n == 4 then
        suffix = math.random(197, 310)
      else
        suffix = ""
      end

      local text = choices[n]:gsub("{[^}]*}", suffix)
      api.popup(text, ch.engineer_1)
    end,
  },

  _engineer_2_rotates_valve = cutscene.make {
    boring_flag = true,
    enabled = true,
    mode = "sequential",
    characters = {
      engineer_2 = {},
    },

    _condition_t = 3,
    _condition = function(self, dt, ch, ps)
      if ch.engineer_2.position ~= ps.engineer_2 then
        State.runner:remove(self)
        return false
      end

      self._condition_t = self._condition_t - dt
      if self._condition_t <= 0 then
        self._condition_t = 30
        return true
      end
      return false
    end,

    _run = function(self, ch, ps, sp)
      ch.engineer_2:rotate(Vector.down)
      actions.interact:act(ch.engineer_2)
    end,
  },

  _detective_experiment = cutscene.make {
    enabled = true,
    characters = {
      engineer_3 = {},
      device_panel = {optional = true},
    },

    _condition = function(self, dt, ch, ps)
      return not State:exists(ch.device_panel)
    end,

    _run = function(self, ch, ps, sp)
      async.sleep(.5)
      ch.engineer_3:rotate(Vector.down)
      async.sleep(2)
      ch.engineer_3:rotate(Vector.up)
    end,
  },

  _304_room_description = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/304_room_description.ms",
    characters = {
      player = {},
      engineer_1 = {},
      engineer_2 = {},
      engineer_3 = {},
      engineer_4 = {},
      steam_source = {},
    },

    _condition = function(self, dt, ch, ps)
      return State.player.position == ps.detective_exit
    end,

    _run = function(self, ch, ps, sp)
      sp:lines()

      State.runner:run_task(function()
        ch.engineer_3:rotate(Vector.down)
        ch.engineer_4:rotate(Vector.down)
        async.sleep(2)
        ch.engineer_3:rotate(Vector.up)
        ch.engineer_4:rotate(Vector.up)
      end)
      sp:lines()

      local sc = State.runner.scenes._302_half_elf
      sc:_run(ch, ps, screenplay.new(sc.screenplay, ch))
      sp:lines()

      sc = State.runner.scenes._engineer_2_rotates_valve
      sc:_run(ch, ps)
      sp:lines()

      api.autosave()
    end,
  },

  _306_interrogation_half_elf = cutscene.make {
    enabled = true,
    mode = "sequential",
    screenplay = "assets/screenplay/306_interrogation_half_elf.ms",
    characters = {
      player = {},
      engineer_1 = {},
    },

    _on_add = function(self, ch, ps)
      interactive.mix_in(ch.engineer_1)
    end,

    _condition = function(self, dt, ch, ps)
      return ch.engineer_1.was_interacted_by == State.player
    end,

    _run = function(self, ch, ps, sp)
      State.rails.dreamers_talked_to[1] = true
      sp:lines()

      local options = sp:start_options()
      while true do
        local n = api.options(options)
        if n == 4 then break end
        sp:start_option(n)
          sp:lines()
        sp:finish_option()
      end
      sp:finish_options()
    end,
  },

  _307_interrogation_halfling = cutscene.make {
    enabled = true,
    mode = "sequential",
    screenplay = "assets/screenplay/307_interrogation_halfling.ms",
    characters = {
      player = {},
      engineer_2 = {},
    },

    _on_add = function(self, ch, ps)
      interactive.mix_in(ch.engineer_2)
    end,

    _condition = function(self, dt, ch, ps)
      return ch.engineer_2.was_interacted_by == State.player
    end,

    _run = function(self, ch, ps, sp)
      State.rails.dreamers_talked_to[2] = true
      local prev_direction = ch.engineer_2.direction
      api.rotate(ch.engineer_2, State.player)

      sp:lines()
      local options = sp:start_options()
      while true do
        local n = api.options(options)
        if n == 4 then break end
        sp:start_option(n)
          sp:lines()
        sp:finish_option()
      end
      sp:finish_options()

      ch.engineer_2:rotate(prev_direction)
    end,
  },

  _308_interrogation_half_orc = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/308_interrogation_half_orc.ms",
    characters = {
      player = {},
      engineer_3 = {},
    },

    _on_add = function(self, ch, ps)
      interactive.mix_in(ch.engineer_3)
    end,

    _condition = function(self, dt, ch, ps)
      return ch.engineer_3.was_interacted_by == State.player
    end,

    _run = function(self, ch, ps, sp)
      State.rails.dreamers_talked_to[3] = true
      sp:lines()
      local options = sp:start_options()
      while true do
        local n = api.options(options)
        if n == 4 then break end
        sp:start_option(n)
          sp:lines()
        sp:finish_option()
      end
      sp:finish_options()
    end,
  },

  _309_interrogation_dwarf = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/309_interrogation_dwarf.ms",
    characters = {
      player = {},
      engineer_4 = {},
    },

    _on_add = function(self, ch, ps)
      interactive.mix_in(ch.engineer_4)
    end,

    _condition = function(self, dt, ch, ps)
      return ch.engineer_4.was_interacted_by == State.player
    end,

    _run = function(self, ch, ps, sp)
      State.rails.dreamers_talked_to[4] = true
      local prev_direction = ch.engineer_4.direction
      api.rotate(ch.engineer_4, State.player)

      sp:lines()
      local options = sp:start_options()
      if not State.player.inventory.gloves then
        options[4] = nil
      end

      while true do
        local n = api.options(options)
        if n == 5 then break end
        sp:start_option(n)
          if n == 4 then
            ch.engineer_4.inventory.gloves = State.player.inventory.gloves
            State.player.inventory.gloves = nil
            State.rails.given_up_gloves = true
          end
          sp:lines()
        sp:finish_option()
      end
      sp:finish_options()

      ch.engineer_4:rotate(prev_direction)
    end,
  },

  _310_warning = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/310_warning.ms",

    _condition = function(self, dt, ch, ps)
      return State.rails.quests.detective == stages.detective._0020_investigate
        and State.player.position == ps.detective_exit_warning
    end,

    _run = function(self, ch, ps, sp)
      api.order(sp:literal())
    end,
  },
}
