local item = require("engine.tech.item")
local sprite = require("engine.tech.sprite")
local interactive = require("engine.tech.interactive")
local screenplay = require("engine.tech.screenplay")
local async = require("engine.tech.async")
local actions = require("engine.mech.actions")
local stages = require("level.logic.stages")
local api = require("engine.tech.api")
local cutscene = require("engine.tech.cutscene")


return {
  _300_black_door = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/300_black_door.ms",

    _condition = function(self, dt, ch, ps)
      return not State:exists(State.level.entities.detective_door)
    end,

    _run = function(self, ch, ps, sp)
      api.order(sp:literal())
      State.rails:set_quest("detective", stages.detective._0020_investigate)
    end,
  },

  _302_half_elf = cutscene.make {
    boring_flag = true,
    enabled = true,
    mode = "sequential",
    screenplay = "assets/screenplay/302_half_elf.ms",
    characters = {
      engineer_1 = {},
    },

    _on_add = function(self, ch, ps)
      ch.engineer_1:rotate(Vector.down)
      ch.engineer_1:animate("holding", true, true)
    end,

    _condition_t = 5,
    _condition = function(self, dt, ch, ps)
      if ch.engineer_1.position ~= ps.engineer_1 then
        State.runner:remove(self)
        return false
      end

      self._condition_t = self._condition_t - dt
      if self._condition_t <= 0 then
        self._condition_t = Random.float(30, 40)
        return true
      end
      return false
    end,

    _run = function(self, ch, ps, sp)
      local choices = sp:literal():split("\n")
      local n = math.random(#choices)

      local suffix
      if n == 1 then
        suffix = ("%.2f"):format(Random.float(1.5, 2.7))
      elseif n == 2 then
        suffix = math.random(40, 80)
      elseif n == 3 then
        suffix = ("%.2f"):format(Random.float(2.6, 5.2))
      elseif n == 4 then
        suffix = math.random(197, 310)
      else
        suffix = ""
      end

      local text = choices[n]:gsub("{[^}]*}", suffix)
      api.popup(text, ch.engineer_1)
    end,
  },

  _engineer_2_rotates_valve = cutscene.make {
    boring_flag = true,
    enabled = true,
    mode = "sequential",
    characters = {
      engineer_2 = {},
    },

    _condition_t = 3,
    _condition = function(self, dt, ch, ps)
      if ch.engineer_2.position ~= ps.engineer_2 then
        State.runner:remove(self)
        return false
      end

      self._condition_t = self._condition_t - dt
      if self._condition_t <= 0 then
        self._condition_t = 30
        return true
      end
      return false
    end,

    _run = function(self, ch, ps, sp)
      ch.engineer_2:rotate(Vector.down)
      actions.interact:_act(ch.engineer_2)
    end,
  },

  _detective_experiment = cutscene.make {
    enabled = true,
    characters = {
      engineer_3 = {},
      device_panel = {optional = true},
    },

    _condition = function(self, dt, ch, ps)
      return not State:exists(ch.device_panel)
    end,

    _run = function(self, ch, ps, sp)
      async.sleep(.5)
      ch.engineer_3:rotate(Vector.down)
      async.sleep(2)
      ch.engineer_3:rotate(Vector.up)
    end,
  },

  _304_room_description = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/304_room_description.ms",
    characters = {
      player = {},
      engineer_1 = {},
      engineer_2 = {},
      engineer_3 = {},
      engineer_4 = {},
      steam_source = {},
    },

    _condition = function(self, dt, ch, ps)
      return State.player.position == ps.detective_exit
    end,

    _run = function(self, ch, ps, sp)
      sp:lines()

      State.runner:run_task(function()
        ch.engineer_3:rotate(Vector.down)
        ch.engineer_4:rotate(Vector.down)
        async.sleep(2)
        ch.engineer_3:rotate(Vector.up)
        ch.engineer_4:rotate(Vector.up)
      end)
      sp:lines()

      local sc = State.runner.scenes._302_half_elf
      sc:_run(ch, ps, screenplay.new(sc.screenplay, ch))
      sp:lines()

      sc = State.runner.scenes._engineer_2_rotates_valve
      sc:_run(ch, ps)
      sp:lines()

      api.autosave()
    end,
  },

  _306_interrogation_half_elf = cutscene.make {
    enabled = true,
    mode = "sequential",
    screenplay = "assets/screenplay/306_interrogation_half_elf.ms",
    characters = {
      player = {},
      engineer_1 = {},
    },

    _on_add = function(self, ch, ps)
      interactive.mix_in(ch.engineer_1)
    end,

    _condition = function(self, dt, ch, ps)
      return ch.engineer_1.was_interacted_by == State.player
    end,

    _run = function(self, ch, ps, sp)
      State.rails:talk_to(1)
      sp:lines()

      local options = sp:start_options()
      while true do
        local n = api.options(options)
        if n == 4 then break end
        sp:start_option(n)
          sp:lines()
        sp:finish_option()
      end
      sp:finish_options()
    end,
  },

  _307_interrogation_halfling = cutscene.make {
    enabled = true,
    mode = "sequential",
    screenplay = "assets/screenplay/307_interrogation_halfling.ms",
    characters = {
      player = {},
      engineer_2 = {},
    },

    _on_add = function(self, ch, ps)
      interactive.mix_in(ch.engineer_2)
    end,

    _condition = function(self, dt, ch, ps)
      return ch.engineer_2.was_interacted_by == State.player
    end,

    _run = function(self, ch, ps, sp)
      State.rails:talk_to(2)
      local prev_direction = ch.engineer_2.direction
      api.rotate(ch.engineer_2, State.player)

      sp:lines()
      local options = sp:start_options()
      while true do
        local n = api.options(options)
        if n == 4 then break end
        sp:start_option(n)
          sp:lines()
        sp:finish_option()
      end
      sp:finish_options()

      ch.engineer_2:rotate(prev_direction)
    end,
  },

  _308_interrogation_half_orc = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/308_interrogation_half_orc.ms",
    characters = {
      player = {},
      engineer_3 = {},
    },

    _on_add = function(self, ch, ps)
      interactive.mix_in(ch.engineer_3)
    end,

    _condition = function(self, dt, ch, ps)
      return ch.engineer_3.was_interacted_by == State.player
        and State.rails.quests.detective == stages.detective._0020_investigate
    end,

    _run = function(self, ch, ps, sp)
      State.rails:talk_to(3)
      sp:lines()
      local options = sp:start_options()
      while true do
        local n = api.options(options)
        if n == 4 then break end
        sp:start_option(n)
          sp:lines()
        sp:finish_option()
      end
      sp:finish_options()
    end,
  },

  _309_interrogation_dwarf = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/309_interrogation_dwarf.ms",
    characters = {
      player = {},
      engineer_4 = {},
    },

    _on_add = function(self, ch, ps)
      interactive.mix_in(ch.engineer_4)
    end,

    _condition = function(self, dt, ch, ps)
      return ch.engineer_4.was_interacted_by == State.player
    end,

    _run = function(self, ch, ps, sp)
      State.rails:talk_to(4)
      local prev_direction = ch.engineer_4.direction
      api.rotate(ch.engineer_4, State.player)

      sp:lines()
      local options = sp:start_options()
      if not State.player.inventory.gloves then
        options[4] = nil
      end

      while true do
        local n = api.options(options)
        if n == 5 then break end
        sp:start_option(n)
          if n == 4 then
            ch.engineer_4.inventory.gloves = State.player.inventory.gloves
            State.player.inventory.gloves = nil
            State.rails.given_up_gloves = true
            options[4] = nil
          end
          sp:lines()
        sp:finish_option()
      end
      sp:finish_options()

      ch.engineer_4:rotate(prev_direction)
    end,
  },

  _310_warning = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/310_warning.ms",

    _condition = function(self, dt, ch, ps)
      return State.rails.quests.detective == stages.detective._0020_investigate
        and State.player.position == ps.detective_exit_warning
    end,

    _run = function(self, ch, ps, sp)
      api.order(sp:literal())
    end,
  },

  _detective_leaving = cutscene.make {
    enabled = true,

    _condition = function(self, dt, ch, ps)
      return api.distance(State.player, ps.detective_exit) > 20
        and State.rails.quests.detective == stages.detective._0020_investigate
    end,

    _run = function(self, ch, ps, sp)
      State.rails:rront_runs_away()
    end,
  },

  _rront_runs_away = cutscene.make {
    enabled = true,
    in_combat_flag = true,
    characters = {
      engineer_3 = {},
    },

    _condition = function(self, dt, ch, ps)
      return ch.engineer_3.position == ps.detective_exit
    end,

    _run = function(self, ch, ps, sp)
      async.sleep(.5)
      State.rails:rront_runs_away()
    end,
  },

  _320_rront_attacked = cutscene.make {
    enabled = true,
    in_combat_flag = true,
    screenplay = "assets/screenplay/320_rront_attacked.ms",
    characters = {
      engineer_3 = {non_locking = true},
      player = {non_locking = true},
    },

    _on_add = function(self, ch, ps)
      self._sub = State.hostility:subscribe(function(source, target)
        if source == State.player and target == ch.engineer_3 then
          self._triggered = true
          State.hostility:unsubscribe(self._sub)
        end
      end)
    end,

    on_remove = function(self)
      State.hostility:unsubscribe(self._sub)
    end,

    _triggered = false,
    _condition = function(self, dt, ch, ps)
      if State.rails.rront_status then
        State.runner:remove(self)
        return false
      end
      return self._triggered
    end,

    _run = function(self, ch, ps, sp)
      local order_1, order_2
      sp:start_single_branch()
        order_1 = sp:literal()
        order_2 = sp:literal()
      sp:finish_single_branch()

      local wait_for_the_kill = function()
        while State:exists(ch.engineer_3) do
          coroutine.yield()
        end
        api.order(order_1)
        async.sleep(3)
        api.order(order_2)
        State.rails:rront_killed()
      end

      api.order(sp:literal())

      while ch.engineer_3.hp > ch.engineer_3:get_max_hp() / 2 do
        coroutine.yield()
      end

      while State.combat:get_current() ~= ch.engineer_3 do
        if not State:exists(ch.engineer_3) then
          return wait_for_the_kill()
        end
        coroutine.yield()
      end

      api.lock(State.player)
      sp:lines()
      api.unlock(State.player)

      api.lock(ch.engineer_3)

      local kept_peace = true
      local sub = State.hostility:subscribe(function(source, target)
        if source == State.player and target == ch.engineer_3 then
          kept_peace = false
        end
      end)

      while State.combat:get_current() == State.player do
        if not State:exists(ch.engineer_3) then
          return wait_for_the_kill()
        end
        coroutine.yield()
      end

      State.hostility:unsubscribe(sub)

      api.unlock(ch.engineer_3)
      if not kept_peace then
        return wait_for_the_kill()
      end
      State.hostility:set("half_orc", "player", nil)
      ch.engineer_3.portrait = sprite.image("assets/portraits/half_orc.png")

      api.rotate(ch.engineer_3, State.player)
      api.lock(State.player)
      sp:lines()

      local options = sp:start_options()
      local looped = true
      while looped do
        local n = api.options(options, true)
        sp:start_option(n)
          if n == 1 then
            sp:lines()
            ch.engineer_3.name = "Рронт"
            sp:start_single_option()
              sp:lines()
            sp:finish_single_option()
          elseif n == 2 then
            sp:lines()
            sp:start_single_option()
              sp:lines()
            sp:finish_single_option()
          elseif n == 3 then
            sp:lines()
          elseif n == 4 then
            sp:lines()
          else
            sp:lines()
            local n = api.options(sp:start_options())
            sp:finish_options()
            api.unlock(State.player)

            if n == 1 or n == 2 then
              State.hostility:set("half_orc", "player", "enemy")
              State:start_combat({State.player, ch.engineer_3})
              coroutine.yield()
              wait_for_the_kill()
            else
              ch.engineer_3.ai.mercy = true
              while not State.rails.rront_status and State:exists(ch.engineer_3) do
                coroutine.yield()
              end
              if not State:exists(ch.engineer_3) then
                wait_for_the_kill()
              end
            end
            looped = false
          end
        sp:finish_option()
      end
      sp:finish_options()
    end,
  },

  _322_dwarf_start = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/322_dwarf_start.ms",
    characters = {
      player = {},
      engineer_4 = {},
    },

    _condition = function(self, dt, ch, ps)
      return api.distance(State.player, ch.engineer_4) >= 7 and (
        State.rails.rront_status == "ran_away"
        or ch.engineer_4.inventory.gloves
      )
    end,

    _run = function(self, ch, ps, sp)
      ch.engineer_4.portrait = sprite.image("assets/portraits/dwarf.png")
      api.rotate(ch.engineer_4, State.player)
      local promise = api.move_camera(ch.engineer_4.position)
      sp:lines()
      promise:wait()
      api.free_camera()

      api.unlock(State.player)
      State.runner:remove("_309_interrogation_dwarf")
      State.runner.scenes._324_dwarf.enabled = true
      item.set_cue(ch.engineer_4, "highlight", true)
    end,
  },

  _324_dwarf = cutscene.make {
    enabled = false,
    screenplay = "assets/screenplay/324_dwarf.ms",
    characters = {
      player = {},
      engineer_4 = {},
    },

    _condition = function(self, dt, ch, ps)
      return ch.engineer_4.was_interacted_by == State.player
    end,

    _run = function(self, ch, ps, sp)
      ch.engineer_4.interact = nil
      api.rotate(ch.engineer_4, State.player)
      sp:lines()
      sp:start_single_branch(State.player:ability_check("perception", 10) and 1 or 2)
        sp:lines()
      sp:finish_single_branch()

      sp:lines()

      local is_rront_dead = State.rails.rront_status == "dead"
      sp:start_single_branch(is_rront_dead and 1 or 2)
        sp:lines()
        api.options(sp:start_options())
        sp:finish_options()
      sp:finish_single_branch()

      sp:lines({STATUS = is_rront_dead and "убил" or "отпустил"})

      sp:start_single_branch(State.player:ability_check("religion", 16) and 1 or 2)
        sp:lines()
      sp:finish_single_branch()

      local n = api.options(sp:start_options())
      sp:finish_options()

      if n == 1 then
        State.player.bag.amulet = 1
      end
    end,
  },
}
