local dynamic_canvas = {}

--- @class dynamic_canvas
--- @field canvas love.Canvas
--- @field f fun(w: integer, h: integer): integer, integer

dynamic_canvas.mt = {}

--- @type dynamic_canvas[]
local list = {}

--- @param f fun(w: integer, h: integer): integer, integer
--- @return dynamic_canvas
dynamic_canvas.new = function(f)
  local w, h = f(love.graphics.getDimensions())
  local container = {canvas = love.graphics.newCanvas(w, h), f = f}
  table.insert(list, container)
  return container
end

--- @param screen_w integer
--- @param screen_h integer
dynamic_canvas.handle_resize = function(screen_w, screen_h)
  for _, container in ipairs(list) do
    container.canvas = love.graphics.newCanvas(container.f(screen_w, screen_h))
  end
end

--- @param self dynamic_canvas
dynamic_canvas.mt.__serialize = function(self)
  local f = self.f
  return function()
    return dynamic_canvas.new(f)
  end
end

Ldump.mark(dynamic_canvas, {mt = "const"}, ...)
return dynamic_canvas
