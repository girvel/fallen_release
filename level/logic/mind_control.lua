local dynamic_canvas = require("engine.tech.dynamic_canvas")


local mind_control = {}

--- @alias mind_control mind_control_strict|table
--- @class mind_control_strict: entity_strict
--- @field _canvases [love.Canvas, love.Canvas]
--- @field _shader love.Shader
--- @field _t number
local methods = {}
mind_control.mt = {__index = methods}

--- @type sprite.rendered
local this_sprite = {
  type = "rendered",
  anchor = "screen",

  --- @param entity mind_control
  render = function(self, entity, dt)
    entity._t = entity._t + dt
    local FPS = 10
    if entity._t >= 1/FPS then
      entity._t = entity._t - 1/FPS

      local prev_shader = love.graphics.getShader()
      local prev_canvas = love.graphics.getCanvas()
      love.graphics.setCanvas(entity._canvases[1])
      love.graphics.setShader(entity._shader)
        love.graphics.clear()
        love.graphics.draw(entity._canvases[2])
      love.graphics.setShader(prev_shader)
      love.graphics.setCanvas(prev_canvas)

      entity._canvases[1], entity._canvases[2] = entity._canvases[2], entity._canvases[1]
    end
    return entity._canvases[2]
  end,
}

--- @return mind_control
mind_control.new = function()
  local palette do
    palette = {}
    local palette_image_data = love.image.newImageData("assets/sprites/palette.png")
    local w, h = palette_image_data:getDimensions()
    for x = 0, w - 1 do
      for y = 0, h - 1 do
        local r, g, b, a = palette_image_data:getPixel(x, y)
        if a > 0 then
          table.insert(palette, {r, g, b, a})
        end
      end
    end
  end

  local e = {
    codename = "mind_control",
    sprite = this_sprite,
    layer = "fx_over_shadows",
    position = Vector.zero,
    _canvases = {},
    _shader = love.graphics.newShader(
      love.filesystem.read("level/shaders/smoke.frag"):format(#palette),
      nil  --- @diagnostic disable-line:param-type-mismatch
    ),
    _t = 0,
  }

  e._shader:send("palette", unpack(palette))

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
