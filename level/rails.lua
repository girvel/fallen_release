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
  State.runner:extend {
    inn_dialogue = cutscene.make {
      enabled = true,
      screenplay = "assets/screenplay/intro.ms",
      characters = {
        player = {},
      },

      _run = function(self, ch, ps, sp)
        State.player:rotate(Vector.up)
        State.player.fov_r = 0
        State.player.incapacitated = true
        sp:lines()

        State.player.incapacitated = false
        sp:lines()

        api.order(sp:literal()):wait()
      end,
    }
  }
end

Ldump.mark(rails, {mt = "const"}, ...)
return rails
