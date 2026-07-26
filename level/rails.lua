local level = require("engine.tech.level")
local quests = require("level.logic.stages")


local rails = {}

--- @class rails
--- @field quests stages
--- @field has_intro_note boolean
local methods = {}
rails.mt = {__index = methods}

local init_debug
local checkpoints = {}

--- @param checkpoint string?
--- @return rails
rails.new = function(checkpoint)
  if Kernel.debug then init_debug() end
  if checkpoint then
    local init_checkpoint = checkpoints[checkpoint]
    if init_checkpoint then
      init_checkpoint()
    else
      Error("No checkpoint %s defined; available: %s", checkpoint, table.concat(
        Fun.iter(checkpoints):totable(), "\n"
      ))
    end
  end

  State.runner:extend(require("level.scenes.1_intro"))
  return setmetatable({
    quests = quests.new(),
    has_intro_note = false,
  }, rails.mt)
end

init_debug = function()
end

checkpoints.cp2 = function()
  level.unsafe_move(State.player, State.level.positions.cp2)
end

Ldump.mark(rails, {mt = "const"}, ...)
return rails
