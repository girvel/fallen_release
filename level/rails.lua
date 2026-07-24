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
    intro = cutscene.make {
      enabled = true,
      screenplay = "assets/screenplay/intro.ms",
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
        sp:lines()
      end,
    }
  }
end

Ldump.mark(rails, {mt = "const"}, ...)
return rails
