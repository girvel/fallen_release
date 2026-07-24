local rails = {}

--- @class rails
local methods = {}
rails.mt = {__index = methods}

local init_debug

--- @param checkpoint string?
--- @return rails
rails.new = function(checkpoint)
  assert(checkpoint == nil, "No checkpoints available")
  if Kernel.debug then init_debug() end
  State.runner:extend(require("level.scenes.1_intro"))
  return setmetatable({}, rails.mt)
end

init_debug = function()
  State.level.entities.black_door._locked = false
end

Ldump.mark(rails, {mt = "const"}, ...)
return rails
