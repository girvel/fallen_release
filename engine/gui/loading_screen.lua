local animated = require("engine.tech.animated")
local async = require("engine.tech.async")
local ui = require("engine.tech.ui")


local loading_screen = {}

--- @class interval
--- @field start number
--- @field finish number

--- @class mode.loading_screen
--- @field type "loading_screen"
--- @field _stages table<string, interval>
--- @field _loading_coroutine thread
local methods = {}
local mt = {__index = methods}

--- @param loading_coroutine thread
--- @param stages? table<string, interval>
loading_screen.new = function(loading_coroutine, stages)
  return setmetatable({
    type = "loading_screen",
    _loading_coroutine = loading_coroutine,
    _stages = stages,
  }, mt)
end

local bar_animation do
  local result = {}
  animated.mix_in(result, "engine/assets/gui/loading_bar", "no_atlas")
  bar_animation = result.animation.pack.second
end

methods.draw_gui = function(self)
  local frame do
    local stage_id, value = async.resume(self._loading_coroutine)
    if stage_id then
      local stage = self._stages[stage_id]
      value = stage.start + (stage.finish - stage.start) * value
    else
      value = 1
    end
    frame = Math.median(1, math.ceil(value * #bar_animation), #bar_animation)
  end

  local bar_y = love.graphics.getHeight() * 4 / 5

  ui.start_alignment("center")
    ui.start_frame(nil, bar_y - 8)
      ui.image("engine/assets/gui/loading_bar_bg.png")
    ui.finish_frame()
    ui.start_frame(nil, bar_y)
      ui.image(bar_animation[frame].image)
    ui.finish_frame()
  ui.finish_alignment()
end

Ldump.mark(loading_screen, {}, ...)
return loading_screen
