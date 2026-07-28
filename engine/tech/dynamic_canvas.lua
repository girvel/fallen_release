local dynamic_canvas = {}

--- @type table<love.Canvas, {container: table, key: string}>
local map = setmetatable({}, {__mode = "k"})

--- @param container table
--- @param key string
--- @return love.Canvas
dynamic_canvas.new = function(container, key)
  local params = {container = container, key = key}
  local canvas = love.graphics.newCanvasRaw()
  map[canvas] = params
  Ldump.serializer.handlers[canvas] = function()
    return dynamic_canvas.new(container, key)
  end
  return canvas
end

--- @param screen_w integer
--- @param screen_h integer
dynamic_canvas.handle_resize = function(screen_w, screen_h)
  local new_map = {}

  local n = 0
  for prev_canvas, params in pairs(map) do
    local canvas = love.graphics.newCanvasRaw(screen_w, screen_h)
    new_map[canvas] = params
    params.container[params.key] = canvas
    Ldump.serializer.handlers[canvas] = Ldump.serializer.handlers[prev_canvas]
    n = n + 1
  end

  map = new_map
end

Ldump.mark(dynamic_canvas, {}, ...)
return dynamic_canvas
