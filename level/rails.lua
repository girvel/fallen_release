local items = require("level.palette.items")
local item = require("engine.tech.item")
local black_and_white_and_red = require("level.shaders.black_and_white_and_red")
local black_and_white = require("level.shaders.black_and_white")
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
  local ch = State.level.entities
  ch.black_door._locked = false
  item.give(State.player, State:add(items.yellow_gloves()))

  State.runner:extend {
    intro = cutscene.make {
      enabled = true,
      screenplay = "assets/screenplay/intro.ms",
      characters = {
        player = {},
      },

      _run = function(self, ch, ps, sp)
        do return end
        State.player:rotate(Vector.up)
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
          State.shader = black_and_white
          async.sleep(2)
          State.shader = black_and_white_and_red
          async.sleep(5)
          State.shader = nil
        end)
        sp:lines()
        flash:wait()
        async.sleep(1)

        sp:lines()
      end,
    }
  }
end

Ldump.mark(rails, {mt = "const"}, ...)
return rails
