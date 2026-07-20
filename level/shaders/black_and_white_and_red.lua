local colors = require("engine.tech.colors")


local black_and_white_and_red = {
  love_shader = love.graphics.newShader(
    love.filesystem.read("level/shaders/black_and_white_and_red.frag"),
    nil  --- @diagnostic disable-line
  ),
  preprocess = function(self, entity, dt)
    love.graphics.setColor(entity.creature_flag and colors.red or colors.white)
  end,
  deactivate = function()
    love.graphics.setColor(Vector.white)
  end,
}

Ldump.mark(black_and_white_and_red, "const", ...)
return black_and_white_and_red
