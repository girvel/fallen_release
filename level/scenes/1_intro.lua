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
    },

    _run = function(self, ch, ps, sp)
      State.player:rotate(Vector.down)
      local prev_fov = State.player.fov_r
      State.player.fov_r = 0
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

      local wrong_names = map_literal()

      api.scale(10)
      while true do
        Kernel.gui:open_menu("appearance_editor")
        while Kernel.gui:is_opened("appearance_editor") do
          coroutine.yield()
        end
        local reaction = wrong_names[State.player.name:utf_lower()]
        if not reaction then break end
        api.line(State.player, reaction)
      end
      api.scale()

      sp:lines()
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
      api.popup(5, ch.neighbour.position + Vector.down * .5, Random.item(self.snores))
    end,
  },
}
