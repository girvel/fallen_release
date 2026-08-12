local shaders = require("level.shaders")
local dynamic_canvas = require("engine.tech.dynamic_canvas")


local mind_control = {}

--- @alias mind_control mind_control_strict|table
--- @class mind_control_strict: entity_strict
--- @field _canvases [love.Canvas, love.Canvas]
--- @field _shader love.Shader
local methods = {}
mind_control.mt = {__index = methods}

--- @type sprite.rendered
local this_sprite = {
  type = "rendered",
  anchor = "screen",

  --- @param entity mind_control
  render = function(self, entity, dt)
    local prev_shader = love.graphics.getShader()
    local prev_canvas = love.graphics.getCanvas()
    love.graphics.setCanvas(entity._canvases[1])
    love.graphics.setShader(entity._shader)
      love.graphics.clear()
      love.graphics.draw(entity._canvases[2])
    love.graphics.setShader(prev_shader)
    love.graphics.setCanvas(prev_canvas)

    entity._canvases[1], entity._canvases[2] = entity._canvases[2], entity._canvases[1]
    return entity._canvases[2]
  end,
}

--- @return mind_control
mind_control.new = function()
  local e = {
    codename = "mind_control",
    sprite = this_sprite,
    layer = "fx_over_shadows",
    position = Vector.zero,
    _canvases = {},
    _shader = shaders.load_shader("smoke"),
  }
  e._canvases[1] = dynamic_canvas.new(e._canvases, 1)
  e._canvases[2] = dynamic_canvas.new(e._canvases, 2)

  local prev_canvas = love.graphics.getCanvas()
  love.graphics.setCanvas(e._canvases[2])
    love.graphics.clear()
    love.graphics.draw(Kernel.screenshot)
  love.graphics.setCanvas(prev_canvas)

  return setmetatable(e, mind_control.mt)
end

Ldump.mark(mind_control, {mt = "const"}, ...)
return mind_control
