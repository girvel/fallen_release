local tcod = require("engine.tech.tcod")
local level = require("engine.tech.level")
local sprite = require("engine.tech.sprite")
local shadow = {}

local LIGHT_INTENSITY_STEP = .1

--- @param data state.shadow.data
local rerender = function(data)
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
        for x1, y1, _, r in State.grids.solids:rhombus(pos, light_value_int) do
          if map:is_visible_unsafe(x1, y1) then
            local value = data.dynamic:unsafe_get(x1, y1)
              + (light_value_int - r) * LIGHT_INTENSITY_STEP
            data.dynamic:unsafe_set(x1, y1, value)
          end
        end
        map:free()
      end
    end
  end

  local prev_canvas = love.graphics.getCanvas()
  local prev_color = {love.graphics.getColor()}
  love.graphics.setCanvas(data.canvas)
  love.graphics.clear(Vector.transparent)

  local map = State.player.ai._vision_map
  for x = start.x, finish.x do
    for y = start.y, finish.y do
      if not map:is_visible_unsafe(x, y) then goto continue end

      local shadow_value = data.static:unsafe_get(x, y)
      local light_value = data.dynamic:unsafe_get(x, y)
      local total_value = shadow_value - light_value

      if total_value > 0 then
        love.graphics.setColor(0, 0, 0, total_value)
        love.graphics.points(x + 1, y + 1)
        -- idk why +1
      end

      ::continue::
    end
  end

  love.graphics.setColor(prev_color)
  love.graphics.setCanvas(prev_canvas)
end

local shadow_sprite = {
  type = "rendered",
  anchor = "world",
}

--- @param entity state.shadow
--- @param dt number
shadow_sprite.render = function(self, entity, dt)
  rerender(entity._data)
  -- entity._data.canvas:newImageData():encode("png", "shadow.png")
  -- os.exit(42)
  return entity._data.canvas, sprite.cell_size
end

--- @alias state.shadow state.shadow_strict|table
--- @class state.shadow_strict: entity_strict
--- @field _data state.shadow.data

--- @class state.shadow.data
--- @field canvas love.Canvas
--- @field static grid<number>
--- @field dynamic grid<number>

--- @param base_grid grid<number>
--- @return state.shadow
shadow.new = function(base_grid)
  return {
    codename = "shadow",
    sprite = shadow_sprite,
    render_size = math.huge,
    layer = "shadows",
    position = Vector.zero,
    _data = {
      canvas = love.graphics.newCanvas(unpack(base_grid.size)),
      static = base_grid,
      dynamic = Grid.new(base_grid.size, function() return 0 end),
    },
  }
end

Ldump.mark(shadow, {},...)
return shadow
