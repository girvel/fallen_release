local memory_shader = require("engine.tech.memory_shader")


--- @param self gui_game
--- @param dt number
local postprocess = function(self, dt)
  love.graphics.setShader()
  if State.shader and State.shader.deactivate then
    State.shader:deactivate()
  end

  if State.player.is_memory_enabled then
    love.graphics.setCanvas(State.player.memory)
    love.graphics.draw(self._main_canvas, unpack(State.camera.offset))
  end

  love.graphics.setCanvas(Kernel.screenshot)
  if State.player.is_memory_enabled then
    love.graphics.setShader(memory_shader.love_shader)
    love.graphics.draw(State.player.memory, unpack(-State.camera.offset))
  end
  love.graphics.setShader()
  love.graphics.draw(self._main_canvas)
end

return postprocess
