--- @class shader
--- @field love_shader love.Shader
--- @field preprocess? fun(self: shader, entity: entity, dt: number)
--- @field update? fun(self: shader, dt: number)
--- @field deactivate? fun(self: shader)

local memory = {
  love_shader = love.graphics.newShader(
    love.filesystem.read("engine/tech/memory_shader/memory.frag"),
    nil  --- @diagnostic disable-line
  ),
}

Ldump.mark(memory, "const", ...)
return memory
