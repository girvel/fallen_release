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
local reflective = Memoize(function(d)
  return {
    love_shader = love.graphics.newShader(
      love.filesystem.read("level/shaders/reflective.frag"),
      nil  --- @diagnostic disable-line:param-type-mismatch
    ),

    preprocess = function(self, entity)
      local image_data = get_reflected_image_data(entity.position, d)
      self.love_shader:send("reflects", image_data ~= nil)
      if image_data then
        self.love_shader:send("reflection", image_data)
      end
    end,
  }
end)

return reflective
