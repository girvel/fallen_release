local colors = require("engine.tech.colors")


local shaders = {}

shaders.load_shader = function(name)
  return love.graphics.newShader(
    love.filesystem.read("level/shaders/"..name..".frag"),
    nil  --- @diagnostic disable-line
  )
end

shaders.bw = {
  love_shader = shaders.load_shader("bwr"),
}

shaders.bwr = {
  love_shader = shaders.load_shader("bwr"),
  preprocess = function(self, entity, dt)
    -- TODO does not activate before SpriteBatch layer => cobwebs are red
    --   but it's kind of fine, really
    love.graphics.setColor(entity.creature_flag and colors.red or colors.white)
  end,
  deactivate = function()
    love.graphics.setColor(Vector.white)
  end,
}

local get_reflected_image_data = function(position, d)
  local reflected = State.grids.solids:slow_get(position + d)
  if not reflected or not reflected.animation then return end

  local animation_codename = reflected.animation.current
  for _, direction_name in ipairs(Vector.direction_names) do
    if animation_codename:ends_with(direction_name) then
      animation_codename = animation_codename:sub(1, -#direction_name - 2)
      goto has_direction
    end
  end

  do return end
  ::has_direction::

  local are_parallel = (d.y == 0) == (reflected.direction.y == 0)
  local reflection_direction = (are_parallel and -1 or 1) * reflected.direction
  local reflection_animation = reflected.animation.pack[
    animation_codename.."_"..Vector.name_from_direction(reflection_direction)
  ]
  local sprite = reflection_animation[
    math.min(math.floor(reflected.animation.frame), #reflection_animation)
  ]
  return sprite and sprite.image
end

--- @param d vector
--- @return shader
shaders.reflective = function(d)
  local result = {
    love_shader = shaders.load_shader("reflective"),
    _prev_reflection = nil,

    preprocess = function(self, entity)
      local reflection = get_reflected_image_data(entity.position, d)
      if self._prev_reflection == reflection then return end
      self._prev_reflection = reflection
      self.love_shader:send("reflects", reflection ~= nil)
      if reflection then
        self.love_shader:send("reflection", reflection)
      end
    end,
  }

  Ldump.serializer.handlers[result] = function()
    return shaders.reflective(d)
  end
  return result
end

shaders.latrine = {
  love_shader = shaders.load_shader("latrine"),
}

Ldump.mark(shaders, {
  bw = "const",
  bwr = "const",
  latrine = "const",
}, ...)
return shaders
