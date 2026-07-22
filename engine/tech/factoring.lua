local sprite = require "engine.tech.sprite"


--- Module for simplifying palette creation
local factoring = {}

--- @class factoring_packer
--- @field offset integer
--- @field _atlas_image love.Image
--- @field _atlas_w integer
--- @field _atlas_h integer
local packer_methods = {}
factoring.packer_mt = {__index = packer_methods}

--- @param atlas_image love.Image
--- @return factoring_packer
factoring.packer = function(atlas_image)
  local w, h = atlas_image:getDimensions()
  return setmetatable({
    offset = 0,
    _atlas_image = atlas_image,
    _atlas_w = w / sprite.cell_size,
    _atlas_h = h / sprite.cell_size,
  }, factoring.packer_mt)
end

--- @param x integer
--- @param y integer
--- @return integer i
--- @return sprite_atlas this_sprite
packer_methods.get = function(self, x, y)
  local i = self.offset + x + (y - 1) * self._atlas_w

  local xoffset = Math.loopmod(i, self._atlas_w)
  local yoffset = math.floor((i - 1) / self._atlas_w + 1)
  if xoffset > self._atlas_w or yoffset > self._atlas_h then
    Error(
      "packer:get(%s, %s) -> (%s, %s) with atlas of size (%s, %s)",
      x, y, xoffset, yoffset, self._atlas_w, self._atlas_h
    )
  end

  return i, sprite.from_atlas(i, sprite.cell_size, self._atlas_image)
end

--- @param local_i integer
--- @return integer i
--- @return sprite_atlas this_sprite
packer_methods.geti = function(self, local_i)
  local i = self.offset + local_i

  local size = self._atlas_w * self._atlas_h
  if i > size then
    Error("packer:geti(%s) -> %s with atlas of size %s", local_i, i, size)
  end

  return i, sprite.from_atlas(i, sprite.cell_size, self._atlas_image)
end

Ldump.mark(factoring, {}, ...)
return factoring
