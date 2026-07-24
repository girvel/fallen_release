local colors = require("engine.tech.colors")


local bwr = {
  love_shader = love.graphics.newShader(
    love.filesystem.read("level/shaders/bwr.frag"),
    nil  --- @diagnostic disable-line
  ),
  preprocess = function(self, entity, dt)
    love.graphics.setColor(entity.creature_flag and colors.red or colors.white)
  end,
  deactivate = function()
    love.graphics.setColor(Vector.white)
  end,
}

Ldump.mark(bwr, "const", ...)
return bwr
