local dynamic_canvas = require("engine.tech.dynamic_canvas")


local game = {}

--- @alias gui_input_mode "normal"|"target"

--- @class gui_game
--- @field type "game"
--- @field _sprite_batches table<string, love.SpriteBatch>
--- @field _main_canvas love.Canvas
--- @field _bg_canvas love.Canvas
--- @field _bg_offset number
local methods = {
  draw_entity = require("engine.gui.game.draw_entity"),
  draw_gui = require("engine.gui.game.draw_gui"),
  draw_grid = require("engine.gui.game.draw_grid"),
  preprocess = require("engine.gui.game.preprocess"),
  postprocess = require("engine.gui.game.postprocess"),
}

game.mt = {__index = methods}

game.new = function()
  local bg_canvas
  if State.level.background then
    bg_canvas = love.graphics.newCanvas(State.level.background.sprite.image:getDimensions())
  end

  local result = {
    type = "game",
    _sprite_batches = Fun.iter(State.level.atlases)
      :map(function(layer, base_image) return layer, love.graphics.newSpriteBatch(base_image) end)
      :tomap(),
    _bg_canvas = bg_canvas,
    _bg_offset = 0,
  }
  result._main_canvas = dynamic_canvas.new(result, "_main_canvas")
  return setmetatable(result, game.mt)
end

Ldump.mark(game, {mt = "const"}, ...)
return game
