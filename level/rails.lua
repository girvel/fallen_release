local interactive = require("engine.tech.interactive")
local async = require("engine.tech.async")
local sprite = require("engine.tech.sprite")
local health = require("engine.mech.health")
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

--- @alias rails.alcohol_source "flask"|"rum"|"ethanol"

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
--- @field let_rront_go boolean?
--- @field met_son_mary boolean?
--- @field met_markiss boolean?
--- @field met_dwarf boolean?
--- @field resists_son_mary boolean?
--- @field did_markiss_help boolean?
--- @field lunch_started boolean?
--- @field flask_noticed boolean?
--- @field source_of_first_alcohol rails.alcohol_source?
--- @field read_captain_door_note boolean?
--- @field player_nickname string?
--- @field did_dreamers_kill_possessed boolean?
--- @field seen_water boolean?
local methods = {}
rails.mt = {__index = methods}

local init_debug, init_factions, init_audio, init_characters
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
  init_characters()
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
    api.lock(State.player)
    api.options({"1", "2", "3", "4", "5", "6", "7", "8", "9"})
    api.unlock(State.player)
    -- Kernel.gui:open_menu("creator")
    -- Kernel.gui._mode:submit()
  end)
end

init_factions = function()
  State.hostility:set("monsters", "player", "enemy")
  State.hostility:set("player", "monsters", "enemy")
  State.hostility:set("canteen_dreamers", "canteen_dreamer_flask", "ally")
  State.hostility:set("canteen_dreamer_flask", "canteen_dreamers", "ally")
end

init_audio = function()
  -- loading audio takes a lot of time
  local sometimes = async.sometimes(1)
  local playlist = {}
  table.insert(playlist, sound.new("assets/sounds/music/doom.mp3", .1))
  sometimes:yield()
  table.insert(playlist, sound.new("assets/sounds/music/drone_ambience.mp3", .5))
  sometimes:yield()
  table.insert(playlist, sound.new("assets/sounds/music/drone_1.mp3", .1))
  sometimes:yield()
  table.insert(playlist, sound.new("assets/sounds/music/drone_2.mp3", .1))
  sometimes:yield()
  State.audio:set_playlist(playlist)
end

init_characters = function()
  local ch = State.level.entities
  ch.valve = ch.guard_b.inventory.offhand
end

local skip_intro = function(self)
  State.runner:remove("_100_intro")
  State.runner:remove("_108_leaving_room")
  State.runner:remove("wandering_away")
  self.intro_note_status = "picked_up"
  State:remove(State.level.entities.intro_note)
  self:set_quest("warmup", stages.warmup._0010_intro_heard)
end

--- @param this_rails rails
checkpoints.cp1 = function(this_rails)
  skip_intro(this_rails)
  this_rails:transition_2_warmup()
  level.unsafe_move(State.player, State.level.positions.cp1)
end

--- @param this_rails rails
checkpoints.cp2 = function(this_rails)
  skip_intro(this_rails)
  this_rails:transition_2_warmup()
  level.unsafe_move(State.player, State.level.positions.officer_room_enter)
end

--- @param this_rails rails
checkpoints.cp3 = function(this_rails)
  skip_intro(this_rails)
  this_rails:transition_2_warmup()
  this_rails:transition_3_detective()
  level.unsafe_move(State.player, State.level.positions.cp3)
  this_rails:set_quest("warmup", stages.warmup._1000_bird_fed)
  this_rails:set_quest("detective", stages.detective._0020_investigate)
  State.runner:remove("_304_room_description")
  State.player.xp = xp.for_level[3]
  item.give(State.player, items.greatsword())
end

--- @param this_rails rails
checkpoints.cp4 = function(this_rails)
  skip_intro(this_rails)
  this_rails:transition_2_warmup()
  this_rails:transition_3_detective()
  level.unsafe_move(State.player, State.level.positions.cp4)
  this_rails:set_quest("warmup", stages.warmup._1000_bird_fed)
  this_rails:rront_runs_away()
  State.runner:remove("_304_room_description")
  State.runner:remove("_322_dwarf_start")
  State.player.xp = xp.for_level[3]
  item.give(State.player, items.greatsword())
end

checkpoints.cp5 = function(this_rails)
  skip_intro(this_rails)
  this_rails:transition_2_warmup()
  this_rails:transition_3_detective()
  level.unsafe_move(State.player, State.level.positions.cp5)
  this_rails:set_quest("warmup", stages.warmup._1000_bird_fed)
  this_rails:rront_runs_away()
  State.runner:remove("_304_room_description")
  State.runner:remove("_322_dwarf_start")
  State.player.xp = xp.for_level[3]
  item.give(State.player, items.greatsword())
  this_rails.met_son_mary = true
  this_rails:set_quest("alcohol", stages.alcohol._0030_return)

  local ch = State.level.entities
  ch.bridge_megadoor3._locked = false
  ch.bridge_megadoor3:on_interact(State.player)
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
  State.runner:extend(love.filesystem.load("level/scenes/4_open.lua")())

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
  self:start_lunch()
  self:set_quest("detective", stages.detective._1000_completed)
  api.autosave("Диверсант устранён")
  self.rront_status = "dead"
end

methods.start_lunch = function(self)
  self.lunch_started = true

  local ch = State.level.entities
  local ps = State.level.positions

  item.set_cue(ch.soup_cauldron, "highlight", true)
  if State:exists(ch.cook) then
    level.unsafe_move(ch.cook, ps.cook_chilling)
  end

  self.did_dreamers_kill_possessed = ch.possessed and ch.possessed.hp > 0
  if self.did_dreamers_kill_possessed then
    health.damage(ch.possessed, 1000)
  end

  local possessed_position = ch.possessed and ch.possessed.position
  if not possessed_position
    or api.distance(possessed_position, ps.possessed_spawn) > 10
  then
    possessed_position = ps.possessed_spawn
  end

  local killer_counter = 0
  local bfs = State.grids.solids:bfs(possessed_position)
  bfs()
  for p, e in bfs do
    if e then bfs:discard() end
    killer_counter = killer_counter + 1
    if killer_counter == 3 and self.did_dreamers_kill_possessed then
      humanoid.add_body({position = p})  --- @diagnostic disable-line
      break
    end

    local killer = solids.dreamer({faction = "canteen_killers"})
    killer:rotate((possessed_position - p):normalized2())
    ch["canteen_killer_"..killer_counter] = State:add_at(killer, p, "solids")

    if killer_counter == 3 then break end
  end

  for i = 1, 3 do
    for p, e in State.grids.solids:bfs(ps["canteen_dreamer_spawn_"..i]) do
      if not e then
        State:add_at(solids.dreamer({faction = "canteen_dreamers"}), p, "solids")
        break
      end
    end
  end

  for p, e in State.grids.solids:bfs(ps.canteen_dreamer_spawn_flask) do
    if not e then
      local dreamer = solids.dreamer({faction = "canteen_dreamer_flask", race = "half_elf"})
      dreamer.inventory.right_pocket = items.flask()
      dreamer.portrait = sprite.image("assets/portraits/half_elf.png")
      interactive.mix_in(dreamer)
      State:add_at(dreamer, p, "solids")
      ch.canteen_dreamer_flask = dreamer
      break
    end
  end

  if self.flask_noticed then
    item.set_cue(ch.canteen_dreamer_flask, "highlight", true)
  end
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

--- @param source rails.alcohol_source
methods.alcohol_pick_up = function(self, source)
  State.player.bag.alcohol = State.player.bag.alcohol + 1
  if not self.source_of_first_alcohol then
    self.source_of_first_alcohol = source
  end
end

methods.get_valve = function()
  State.player.bag.valve = State.player.bag.valve + 1
  local ch = State.level.entities
  State:remove(ch.valve)
  ch.guard_b.inventory.offhand = nil
  item.set_cue(ch.bridge_megadoor3, "highlight", true)
end

methods.freedom = function(self)
  if not self.rront_status then
    self:rront_runs_away()
  end
end

methods.notice_flask = function(self)
  if self.flask_noticed then return end
  local dreamer = rawget(State.level.entities, "canteen_dreamer_flask")
  if State:exists(dreamer) then
    item.set_cue(dreamer, "highlight", true)
  end
  self.flask_noticed = true
end

Ldump.mark(rails, {mt = "const"}, ...)
return rails
