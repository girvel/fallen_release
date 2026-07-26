local rails = {}

--- @class rails
--- @field quests rails.quests
--- @field has_intro_note boolean
local methods = {}
rails.mt = {__index = methods}

--- @class rails.quests
--- @field warmup integer

local init_debug

--- @param checkpoint string?
--- @return rails
rails.new = function(checkpoint)
  assert(checkpoint == nil, "No checkpoints available")
  if Kernel.debug then init_debug() end
  State.runner:extend(require("level.scenes.1_intro"))
  return setmetatable({
    quests = {
      warmup = 0,
    },
    has_intro_note = false,
  }, rails.mt)
end

init_debug = function()
  State.level.entities.black_door._locked = false
  State.runner:run_task(function()
    State.rails.quests.warmup = 999
    State.rails.has_intro_note = true
  end)
end

Ldump.mark(rails, {mt = "const"}, ...)
return rails
