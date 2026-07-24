local bw = {
  love_shader = love.graphics.newShader(
    love.filesystem.read("level/shaders/bwr.frag"),
    nil  --- @diagnostic disable-line
  )
}

Ldump.mark(bw, "const", ...)
return bw
