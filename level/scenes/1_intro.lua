local ui = require("engine.tech.ui")
local stages = require("level.logic.stages")
local interactive = require("engine.tech.interactive")
local item = require("engine.tech.item")
local abilities = require("engine.mech.abilities")
local on_solids = require("level.palette.on_solids")
local xp = require("engine.mech.xp")
local bwr = require("level.shaders.bwr")
local bw = require("level.shaders.bw")
local async = require("engine.tech.async")
local api = require("engine.tech.api")
local cutscene = require("engine.tech.cutscene")


return {
  _100_intro = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/100_intro.ms",
    characters = {
      player = {},
      intro_note = {},
    },

    _run = function(self, ch, ps, sp)
      State.player.curtain_color = Vector.black
      State.player:rotate(Vector.down)
      local prev_fov = State.player.fov_r
      State.player.fov_r = 0
      async.sleep(1)

      local logo_alpha = 0
      State.player.curtain_draw = function()
        ui.start_color(V(1, 1, 1, logo_alpha))
          ui.start_alignment("center", "center")
          ui.start_font(100)
            ui.text("St.Celest")
          ui.finish_font()
          ui.finish_alignment()

          local h = ui.get_context().frame.h
          ui.start_frame(nil, h / 2 + 50)
          ui.start_alignment("center")
          ui.start_font(50)
            ui.text("presents")
          ui.finish_font()
          ui.finish_alignment()
          ui.finish_frame()
        ui.finish_color()
      end

      local max_timeout = 3
      local timeout = max_timeout
      while timeout > 0 do
        logo_alpha = 1 - timeout / max_timeout
        timeout = timeout - coroutine.yield()
      end

      async.sleep(2)
      max_timeout = 2
      timeout = max_timeout
      while timeout > 0 do
        local v = timeout / max_timeout
        logo_alpha = v
        State.player.curtain_color = V(0, 0, 0, v)
        timeout = timeout - coroutine.yield()
      end

      async.sleep(2)

      State.player.incapacitated = true
      State.player.suggestion = sp:literal()
      sp:lines()

      State.player.suggestion = nil
      sp:lines()

      State.player.incapacitated = false
      sp:lines()

      api.order(sp:literal())
      async.sleep(3)

      sp:lines()

      local flash = State.runner:run_task(function()
        State.player.fov_r = prev_fov
        State.shader = bw
        async.sleep(.2)
        State.shader = bwr
        async.sleep(.5)
        State.shader = nil
        api.travel_scripted(State.player, State.player.position + Vector.up)
      end)
      sp:lines()
      flash:wait()

      async.sleep(1)
      sp:lines()

      State.runner.scenes._102_snoring.enabled = true
      State.runner.scenes._102_snoring.triggered = true
      sp:lines()

      State.player.xp = xp.for_level[2]
      State.level.locked_entities[State.player] = nil
      Kernel.gui:open_menu("creator")
      while Kernel.gui:is_opened("creator") do
        coroutine.yield()
      end
      State.level.locked_entities[State.player] = true

      local sorted_abilities = Fun.iter(abilities.list)
        :map(function(aname) return {aname, State.player:get_score(aname)} end)
        :totable()
      table.sort(sorted_abilities, function(a, b) return a[2] < b[2] end)

      local map_literal = function()
        local result = {}
        for _, line in ipairs(sp:literal():split("\n")) do
          local key, value = line:match("^([^:]+):%s*(.*)$")
          result[key] = value
        end
        return result
      end

      api.line(State.player, map_literal()[sorted_abilities[6][1]])
      api.line(State.player, map_literal()[sorted_abilities[5][1]])
      api.line(State.player, map_literal()[sorted_abilities[1][1]])

      api.travel_scripted(State.player, State.player.position + Vector.down):wait()
      api.scale(10)
      local wrong_names = map_literal()
      while true do
        Kernel.gui:open_menu("appearance_editor")
        while Kernel.gui:is_opened("appearance_editor") do
          coroutine.yield()
        end
        local reaction = wrong_names[State.player.name:utf_lower()]
        if not reaction then break end
        api.line(State.player, reaction)
      end

      api.scale():next(function()
      -- memory glitches with api.scale, remove this when it's fixed
        local prev_canvas = love.graphics.getCanvas()
        love.graphics.setCanvas(State.player.memory)
        love.graphics.clear()
        love.graphics.setCanvas(prev_canvas)
      end)

      api.line(State.player, '"'..State.player.name..'"?')
      sp:lines()

      api.order(sp:literal())
      sp:lines()

      item.set_cue(ch.intro_note, "highlight", true)
      interactive.mix_in(ch.intro_note)
      ch.intro_note.name = "записка"

      State.rails:set_quest("warmup", stages.warmup._0010_intro_heard)
    end,
  },

  _102_snoring = cutscene.make {
    enabled = false,
    triggered = false,
    mode = "sequential",
    snores = love.filesystem.read("assets/screenplay/102_snoring.txt"):strip():split("\n"),
    characters = {
      neighbour = {},
    },

    _on_add = function(self, ch, ps)
      ch.neighbour:rotate(Vector.up)
      on_solids.fs.lie(ch.neighbour, ps.intro_upper_bunk, "upper")
    end,

    activation_t = 45,
    _condition = function(self, dt, ch, ps)
      self.activation_t = self.activation_t + dt
      if self.activation_t >= 45 then
        self.activation_t = 0
        return true
      end
      return self.triggered
    end,

    _run = function(self, ch, ps)
      self.triggered = false
      api.popup(Random.item(self.snores), ch.neighbour.position + Vector.down * .5)
    end,
  },

  intro_note_pickup = cutscene.make {
    enabled = true,
    characters = {
      intro_note = {},
    },

    _condition = function(self, dt, ch, ps)
      return ch.intro_note.was_interacted_by == State.player
    end,

    _run = function(self, ch, ps, sp)
      State:remove(ch.intro_note)
      State.rails.intro_note_status = "picked_up"
      State.player.suggestion = "Нажмите [J] чтобы открыть журнал"
      local timeout = 10
      while not Kernel.gui:is_opened("journal") and timeout > 0 do
        local dt = coroutine.yield()
        timeout = timeout - dt
      end
      State.player.suggestion = nil
    end,

    _on_cancel = function(self)
      State.player.suggestion = nil
    end,
  },

  _108_leaving_room = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/108_leaving_room.ms",
    characters = {
      player = {}
    },

    _condition = function(self, dt, ch, ps)
      return State.player.position == ps.player_room_exit
    end,

    _run = function(self, ch, ps, sp)
      if State.rails.intro_note_status ~= "none" then return end
      sp:lines()
      State.rails:transition_2_warmup()
    end,
  },

  wandering_away = cutscene.make {
    enabled = true,
    characters = {},

    _condition = function(self, dt, ch, ps)
      return api.distance(State.player, ps.player_room_exit) > 7
    end,

    _run = function(self, ch, ps, sp)
      api.order("Отправляйся в тренировочную комнату")
      State.rails:set_quest("warmup", stages.warmup._0030_left)
    end,
  },
}
