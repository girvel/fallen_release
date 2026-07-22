local sprite = require("engine.tech.sprite")
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

  State.camera:_update(dt)

  local bg = State.level.background
  if bg then
    self._bg_offset = (self._bg_offset + State.level.water_speed * dt) % sprite.cell_size

    local old_canvas = love.graphics.getCanvas()
    love.graphics.setCanvas(self._bg_canvas)
      local offset = math.floor(self._bg_offset)
      love.graphics.draw(bg.sprite.image, 0, offset)
      love.graphics.draw(bg.sprite.image, 0, offset - sprite.cell_size)
    love.graphics.setCanvas(old_canvas)

    local k = State.camera.scale
    local total_k = k * sprite.cell_size
    local dx, dy = unpack(State.camera.offset)
    local vision_map = State.player.ai._vision_map
    for x = State.camera.vision_start.x, State.camera.vision_end.x do
      for y = State.camera.vision_start.y, State.camera.vision_end.y do
        if not vision_map:is_visible_unsafe(x, y) then goto continue end
        local relx = x * total_k - dx
        local rely = y * total_k - dy
        local tile = State.grids.tiles:unsafe_get(x, y)
        if tile then
          love.graphics.setColor(Vector.black)
          love.graphics.rectangle("fill", relx, rely, total_k, total_k)
        else
          love.graphics.setColor(Vector.white)
          love.graphics.draw(self._bg_canvas, relx, rely, 0, k, k)
        end
        ::continue::
      end
    end
    love.graphics.setColor(Vector.white)
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
