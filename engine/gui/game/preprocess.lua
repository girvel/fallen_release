--- @param self gui_game
--- @param dt number
local preprocess = function(self, dt)
  local screen_w, screen_h = love.graphics.getDimensions()

  do
    local w, h = self._temp_canvas:getDimensions()
    if screen_w ~= w or screen_h ~= h then
      self._temp_canvas = love.graphics.newCanvas(screen_w, screen_h)
    end
  end

  do
    local w, h = self._main_canvas:getDimensions()
    if screen_w ~= w or screen_h ~= h then
      self._main_canvas = love.graphics.newCanvas(screen_w, screen_h)
    end
  end

  love.graphics.setCanvas(self._main_canvas)
  love.graphics.clear(0, 0, 0, 0)

  local bg = State.level.background
  if bg then
    local old_canvas = love.graphics.getCanvas()
    love.graphics.setCanvas(self._bg_canvas)
      local offset = Vector.zero
      love.graphics.draw(bg.sprite.image, unpack(offset))
      -- for _, delta in ipairs(Vector.extended_directions) do
      --   love.graphics.draw(bg.sprite.image, unpack(
      --     offset + delta * State.camera.scale
      --   ))
      -- end
    love.graphics.setCanvas(old_canvas)
  end

  local shader = State.shader
  if shader then
    love.graphics.setShader(shader.love_shader)
    if shader.update then
      shader:update(dt)
    end
  end
end

return preprocess
