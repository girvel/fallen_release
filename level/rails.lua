local items = require("level.palette.items")
local item = require("engine.tech.item")
local xp = require("engine.mech.xp")
local api = require("engine.tech.api")
local sound = require("engine.tech.sound")
local humanoid = require("engine.mech.humanoid")
local solids = require("level.palette.solids")
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
--- @field dreamers_talked_to table<integer, boolean>
--- @field talked_to_everybody boolean?
--- @field given_up_gloves boolean
--- @field rront_status "dead"|"ran_away"?
local methods = {}
rails.mt = {__index = methods}

local init_debug, init_factions, init_audio
local checkpoints = {}

--- @param checkpoint string?
--- @return rails
rails.new = function(checkpoint)
  local result = setmetatable({
    quests = quests.new(),
    intro_note_status = "none",
    in_latrine = false,
    dreamers_talked_to = {},
  }, rails.mt)
  State.runner:extend(love.filesystem.load("level/scenes/1_intro.lua")())

  if Kernel.debug then init_debug() end
  init_factions()
  init_audio()
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
  State.runner:run_task(function()
    Kernel.gui:open_menu("creator")
    Kernel.gui._mode:submit()
  end)
end

init_factions = function()
  State.hostility:set("monsters", "player", "enemy")
end

init_audio = function()
  State.audio:set_playlist({
    sound.new("assets/sounds/music/doom.mp3", .1),
    sound.new("assets/sounds/music/drone_ambience.mp3", .5),
    sound.new("assets/sounds/music/drone_1.mp3", .1),
    sound.new("assets/sounds/music/drone_2.mp3", .1),
  })
end

local skip_intro = function(self)
  State.runner:remove("_100_intro")
  State.runner:remove("_108_leaving_room")
  State.runner:remove("wandering_away")
  self.intro_note_status = "picked_up"
  State:remove(State.level.entities.intro_note)
  self:set_quest("warmup", stages.warmup._0010_intro_heard)
end

--- @param rails rails
checkpoints.cp1 = function(rails)
  skip_intro(rails)
  rails:transition_2_warmup()
  level.unsafe_move(State.player, State.level.positions.cp1)
end

--- @param rails rails
checkpoints.cp2 = function(rails)
  skip_intro(rails)
  rails:transition_2_warmup()
  level.unsafe_move(State.player, State.level.positions.officer_room_enter)
end

--- @param rails rails
checkpoints.cp3 = function(rails)
  skip_intro(rails)
  rails:transition_2_warmup()
  rails:transition_3_detective()
  level.unsafe_move(State.player, State.level.positions.cp3)
  rails:set_quest("warmup", stages.warmup._1000_bird_fed)
  rails:set_quest("detective", stages.detective._0020_investigate)
  State.runner:remove("_304_room_description")
  State.player.xp = xp.for_level[3]
  item.give(State.player, items.greatsword())
end

--- @param questname stages.keys
--- @param stage integer
methods.set_quest = function(self, questname, stage)
  if self.quests[questname] < stage then
    State.model.has_new_task = true
    self.quests[questname] = stage
  end
end

methods.transition_2_warmup = function(self)
  State.runner:extend(love.filesystem.load("level/scenes/2_warmup.lua")())
end

methods.transition_3_detective = function(self)
  State.runner:extend(love.filesystem.load("level/scenes/3_detective.lua")())

  local ch = State.level.entities
  local ps = State.level.positions
  ch.detective_door._locked = false
  ch.left_megadoor._locked = false
  ch.left_megadoor:on_interact(State.player)  -- opening

  for i = 1, 2 do
    local e = ch["dining_room_door_"..i]
    if not State:exists(e) then
      State:remove(State.grids.on_solids[e.position])
      State:add_at(solids.door(), e.position, "solids")
    end
  end

  ch.possessed = State:add_at(solids.possessed(), ps.possessed_spawn, "solids")
  ch.possessed:rotate(Vector.left)
  humanoid.add_blood_mark(ch.possessed)
end

methods.rront_runs_away = function(self)
  local ch = State.level.entities
  local ps = State.level.positions

  assert(State:exists(ch.engineer_3))
  api.assert_position(ch.engineer_3, ps.rront_hideout, true)
  api.order("Задача выполнена неудовлетворительно")
  self:set_quest("detective", stages.detective._2000_failed)
  self:start_lunch()
  self.rront_status = "ran_away"
end

methods.rront_killed = function(self)
  assert(not State:exists(State.level.entities.engineer_3))
  State.rails:start_lunch()
  State.rails:set_quest("detective", stages.detective._1000_completed)
  api.autosave("Диверсант устранён")
end

methods.start_lunch = function(self)
  Log.warn("TODO")
end

--- @param i number
methods.talk_to = function(self, i)
  local before = self.dreamers_talked_to[i]
  self.dreamers_talked_to[i] = true
  self.talked_to_everybody = Fun.range(4)
    :all(function(j) return State.rails.dreamers_talked_to[j] end)
  if not before and self.talked_to_everybody then
    State.model.has_new_task = true
  end
end

Ldump.mark(rails, {mt = "const"}, ...)
return rails
