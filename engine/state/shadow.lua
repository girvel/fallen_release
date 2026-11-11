local ffi = require("ffi")
local tcod = require("engine.tech.tcod")
local level = require("engine.tech.level")
local sprite = require("engine.tech.sprite")
local shadow = {}

local LIGHT_INTENSITY_STEP = .1

--- @param data state.shadow.data
--- @param x1 integer
--- @param y1 integer
--- @param x2 integer
--- @param y2 integer
local rerender = function(data, x1, y1, x2, y2)
  local pixels = ffi.cast("Color*", data.image_data:getFFIPointer())
  local map = State.player.ai._vision_map
  local w = State.grids.solids.size.x
  map:refresh_fov(State.player.position, State.player.fov_r)
  for x = x1, x2 do
    for y = y1, y2 do
      if not map:is_visible_unsafe(x, y) then
        pixels[y * w + x].a = 0
        goto continue
      end

      local shadow_value = data.static:unsafe_get(x, y)
      local light_value = data.dynamic:unsafe_get(x, y)
      local total_value = Math.clamp(0, 1, shadow_value - light_value)

      pixels[(y - 1) * w + (x - 1)].a = math.ceil(total_value * 255)

      ::continue::
    end
  end

  data.image:replacePixels(data.image_data)
end

local shadow_sprite = {
  type = "rendered",
  anchor = "world",
}

--- @param entity state.shadow
--- @param dt number
shadow_sprite.render = function(self, entity, dt)
  return entity._data.image, sprite.cell_size
end

--- @alias state.shadow state.shadow_strict|table
--- @class state.shadow_strict: entity_raw_strict
--- @field _data state.shadow.data
local methods = {}
shadow.mt = {__index = methods}

--- @class state.shadow.data
--- @field image_data love.ImageData
--- @field image love.Image
--- @field static grid<number>
--- @field dynamic grid<number>

--- @param base_grid grid<number>
--- @return state.shadow
shadow.new = function(base_grid)
  local image_data = love.image.newImageData(unpack(base_grid.size))
  return setmetatable({
    codename = "shadow",
    sprite = shadow_sprite,
    render_size = math.huge,
    layer = "shadows",
    position = Vector.one,
    _data = {
      image_data = image_data,
      image = love.graphics.newImage(image_data),
      static = base_grid,
      dynamic = Grid.new(base_grid.size, function() return 0 end),
    },
  }, shadow.mt)
end

--- @param entity entity
--- @param value number
methods.change_light_intensity = function(self, entity, value)
  if not entity.grid_layer or entity.light_intensity == value then return end

  local prev_value = entity.light_intensity or 0
  local range = math.ceil(math.max(prev_value, value) / LIGHT_INTENSITY_STEP)
  local dynamic = self._data.dynamic

  entity.light_intensity = value

  -- OPT instead of creating maps, keep a weak hashtable with maps for each entity,
  --   verify range & position before using
  local map = tcod.map(State.grids.solids)
  map:refresh_fov(entity.position, range)
  for x, y, v, r in dynamic:rhombus(entity.position, range) do
    if map:is_visible_unsafe(x, y) then
      local prev_light = math.max(0, prev_value - r * LIGHT_INTENSITY_STEP)
      local light = math.max(0, value - r * LIGHT_INTENSITY_STEP)
      dynamic:unsafe_set(x, y, v + (light - prev_light))
    end
  end
  map:free()

  local grid_w, grid_h = unpack(State.level.grid_size)
  rerender(
    self._data,
    Math.median(1, grid_w, entity.position.x - range),
    Math.median(1, grid_h, entity.position.y - range),
    Math.median(1, grid_w, entity.position.x + range),
    Math.median(1, grid_h, entity.position.y + range)
  )
end

methods.partial_rebuild = function(self)
  local data = self._data

  local grid_w, grid_h = unpack(State.grids.solids.size)
  local screen_half_w, screen_half_h do
    local x, y = unpack(State.camera.vision_size)
    screen_half_w = math.ceil(x/2)
    screen_half_h = math.ceil(y/2)
  end
  local px, py = unpack(State.player.position)
  local padding = math.ceil(1 / LIGHT_INTENSITY_STEP)

  local start_x = Math.median(1, grid_w, px - screen_half_w - padding)
  local start_y = Math.median(1, grid_h, py - screen_half_h - padding)
  local finish_x = Math.median(1, grid_w, px + screen_half_w + padding)
  local finish_y = Math.median(1, grid_h, py + screen_half_h + padding)

  for x = start_x, finish_x do
    for y = start_y, finish_y do
      data.dynamic:unsafe_set(x, y, 0)
    end
  end

  for x = start_x, finish_x do
    for y = start_y, finish_y do
      local light_value = 0
      for _, layer_name in ipairs(level.grid_layers) do
        local e = State.grids[layer_name]:unsafe_get(x, y)
        if e and e.light_intensity then
          light_value = math.max(light_value, e.light_intensity)
        end
      end

      if light_value > 0 then
        local map = tcod.map(State.grids.solids)
        local light_value_int = math.ceil(light_value / LIGHT_INTENSITY_STEP)
        local pos = V(x, y)
        map:refresh_fov(pos, light_value_int)
        for x1, y1, v, r in data.dynamic:rhombus(pos, light_value_int) do
          if map:is_visible_unsafe(x1, y1) then
            local new_value = v + (light_value_int - r) * LIGHT_INTENSITY_STEP
            data.dynamic:unsafe_set(x1, y1, new_value)
          end
        end
        map:free()
      end
    end
  end

  rerender(data, start_x, start_y, finish_x, finish_y)
end

Ldump.mark(shadow, {},...)
return shadow
