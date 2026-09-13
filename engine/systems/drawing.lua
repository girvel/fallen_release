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
    if entity.sprite.type ~= "grid" then
      if (entity.position - State.player.position):abs2() > State.player.fov_r then
        return
      end
    end
    Kernel.gui:draw_entity(entity, dt)
  end,
}
