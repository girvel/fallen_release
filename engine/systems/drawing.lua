local level = require("engine.tech.level")


return Tiny.sortedProcessingSystem {
  codename = "drawing",
  base_callback = "draw",
  filter = function(_, entity)
    return entity.sprite and entity.position and entity.layer
  end,

  compare = function(_, a, b)
    return Table.index_of(level.layers, a.layer) < Table.index_of(level.layers, b.layer)
  end,

  process = function(_, entity, dt)
    local x, y = unpack(entity.position)
    local ax, ay = unpack(State.camera.vision_start)
    local bx, by = unpack(State.camera.vision_end)
    local distance = math.max(0, ax - x, x - bx) + math.max(0, ay - y, y - by)
    if distance <= (entity.render_size or 1) then
      Kernel.gui:draw_entity(entity, dt)
    end
  end,
}
