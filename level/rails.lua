local stages = require("level.logic.stages")
local level = require("engine.tech.level")
local quests = require("level.logic.stages")


local rails = {}

--- @class rails
--- @field quests stages
--- @field intro_note_status "none"|"picked_up"|"read"
--- @field fighting_guide_status "seen"|"picked_up"|"read"?
--- @field tolerates_latrine boolean?
--- @field player_last_fov number?
--- @field in_latrine boolean
local methods = {}
rails.mt = {__index = methods}

local init_debug
local checkpoints = {}

--- @param checkpoint string?
--- @return rails
rails.new = function(checkpoint)
  local result = setmetatable({
    quests = quests.new(),
    intro_note_status = "none",
    in_latrine = false,
  }, rails.mt)
  State.runner:extend(love.filesystem.load("level/scenes/1_intro.lua")())

  if Kernel.debug then init_debug() end
  if checkpoint then
    local init_checkpoint = checkpoints[checkpoint]
    if init_checkpoint then
      init_checkpoint(result)
    else
      Error("No checkpoint %s defined; available: %s", checkpoint, table.concat(
        Fun.iter(checkpoints):totable(), "\n"
      ))
    end
  end

  return result
end

init_debug = function()
  State.player.max_hp = 100
end

local skip_intro = function(self)
  State.runner:remove("_100_intro")
  State.runner:remove("_108_leaving_room")
  State.runner:remove("wandering_away")
  self.intro_note_status = "picked_up"
  State:remove(State.level.entities.intro_note)
  self:set_quest("warmup", stages.warmup._0010_intro_heard)
end

checkpoints.cp1 = function(self)
  skip_intro(self)
  self:transition_2_warmup()
  level.unsafe_move(State.player, State.level.positions.cp1)
end

checkpoints.cp2 = function(self)
  skip_intro(self)
  self:transition_2_warmup()
  level.unsafe_move(State.player, State.level.positions.officer_room_enter)
end

--- @param questname stages.keys
--- @param stage integer
methods.set_quest = function(self, questname, stage)
  if self.quests[questname] < stage then
    State.player.has_new_task = true
    self.quests[questname] = stage
  end
end

methods.transition_2_warmup = function(self)
  State.runner:extend(love.filesystem.load("level/scenes/2_warmup.lua")())
end

Ldump.mark(rails, {mt = "const"}, ...)
return rails
