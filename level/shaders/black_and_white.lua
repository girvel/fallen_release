local black_and_white = {
  love_shader = love.graphics.newShader(
    love.filesystem.read("level/shaders/black_and_white.frag"),
    nil  --- @diagnostic disable-line
  )
}

Ldump.mark(black_and_white, "const", ...)
return black_and_white
