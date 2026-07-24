local on_solids = require("level.palette.on_solids")
local xp = require("engine.mech.xp")
local bwr = require("level.shaders.bwr")
local bw = require("level.shaders.bw")
local async = require("engine.tech.async")
local api = require("engine.tech.api")
local cutscene = require("engine.tech.cutscene")


local rails = {}

--- @class rails
local methods = {}
rails.mt = {__index = methods}

local init_debug

--- @param checkpoint string?
--- @return rails
rails.new = function(checkpoint)
  assert(checkpoint == nil, "No checkpoints available")
  if Kernel.debug then init_debug() end
  return setmetatable({}, rails.mt)
end

init_debug = function()
  State.level.entities.black_door._locked = false

  State.runner:extend {
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
end

Ldump.mark(rails, {mt = "const"}, ...)
return rails
