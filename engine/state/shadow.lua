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

      pixels[y * w + x].a = math.ceil(total_value * 255)

      ::continue::
    end
  end
end

local shadow_sprite = {
  type = "rendered",
  anchor = "world",
}

--- @param entity state.shadow
--- @param dt number
shadow_sprite.render = function(self, entity, dt)
  return love.graphics.newImage(entity._data.image_data), sprite.cell_size
end

--- @alias state.shadow state.shadow_strict|table
--- @class state.shadow_strict: entity_raw_strict
--- @field _data state.shadow.data
local methods = {}
shadow.mt = {__index = methods}

--- @class state.shadow.data
--- @field image_data love.ImageData
--- @field static grid<number>
--- @field dynamic grid<number>

--- @param base_grid grid<number>
--- @return state.shadow
shadow.new = function(base_grid)
  return setmetatable({
    codename = "shadow",
    sprite = shadow_sprite,
    render_size = math.huge,
    layer = "shadows",
    position = Vector.zero,
    _data = {
      image_data = love.image.newImageData(unpack(base_grid.size)),
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

  rerender(
    self._data,
    entity.position.x - range,
    entity.position.y - range,
    entity.position.x + range,
    entity.position.y + range
  )
end

methods.partial_rebuild = function(self)
  Log.trace("partial rebuild")
  local data = self._data
  local grid_size = State.grids.solids.size
  local start = Vector.use(
    Math.median, Vector.one, grid_size,
    State.camera.vision_start - Vector.one * math.ceil(1 / LIGHT_INTENSITY_STEP)
  )
  local finish = Vector.use(
    Math.median, Vector.one, grid_size,
    State.camera.vision_end + Vector.one * math.ceil(1 / LIGHT_INTENSITY_STEP)
  )

  for x = start.x, finish.x do
    for y = start.y, finish.y do
      data.dynamic:unsafe_set(x, y, 0)
    end
  end

  for x = start.x, finish.x do
    for y = start.y, finish.y do
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

  rerender(data, start.x, start.y, finish.x, finish.y)
end

Ldump.mark(shadow, {},...)
return shadow
