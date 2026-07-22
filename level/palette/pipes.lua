local factoring = require("engine.tech.factoring")


local pipes = {}

pipes.ATLAS_IMAGE = love.graphics.newImage("assets/atlases/pipes.png")
local packer = factoring.packer(pipes.ATLAS_IMAGE)

packer.offset = 0
for x = 1, 5 do
  for y = 1, 4 do
    local i, this_sprite = packer:get(x, y)
    pipes[i] = function()
      return {
        boring_flag = true,
        codename = "pipe",
        sprite = this_sprite,
      }
    end
    if x == 5 and y == 1 then break end
  end
end

Ldump.mark(pipes, {}, ...)
return pipes
