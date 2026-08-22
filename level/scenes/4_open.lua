local items = require("level.palette.items")
local no_op = require("engine.mech.ais.no_op")
local on_solids = require("level.palette.on_solids")
local level = require("engine.tech.level")
local actions = require("engine.mech.actions")
local async = require("engine.tech.async")
local sound = require("engine.tech.sound")
local mind_control = require("level.logic.mind_control")
local player_base = require("engine.state.player.base")
local solids = require("level.palette.solids")
local health = require("engine.mech.health")
local interactive = require("engine.tech.interactive")
local item = require("engine.tech.item")
local translation = require("engine.tech.translation")
local stages = require("level.logic.stages")
local api = require("engine.tech.api")
local screenplay = require("engine.tech.screenplay")
local cutscene = require("engine.tech.cutscene")


return {
  _400_markiss = cutscene.make {
    enabled = true,
    mode = "sequential",
    screenplay = "assets/screenplay/400_markiss.ms",
    characters = {
      player = {},
      markiss = {},
    },

    _condition = function(self, dt, ch, ps)
      return ch.markiss.was_interacted_by == State.player
    end,

    _run_i = 0,
    _seen = {},
    _run = function(self, ch, ps, sp)
      self._run_i = self._run_i + 1
      sp:start_branches()
      sp:start_branch(math.min(sp:branches_n(), self._run_i))
        if self._run_i == 1 then
          self._first_time = false
          sp:start_single_branch(ch.markiss.ai.point_i == 1 and 2 or 1)
            sp:lines()
          sp:finish_single_branch()
          sp:lines()
          self._nature_check = State.player:ability_check("nature", 18)
          sp:start_single_branch(self._nature_check and 1 or 2)
            sp:lines()
          sp:finish_single_branch()
        else
          sp:lines()
        end
      sp:finish_branch()
      sp:finish_branches()

      local options = sp:start_options() do
        for _, key in ipairs(self._seen) do
          options[key] = nil
        end

        if State.rails.rront_status ~= "ran_away" then
          options[4] = nil
        end

        if not State.rails.met_son_mary then
          options[5] = nil
        end

        local alcohol = State.rails.quests.alcohol
        if alcohol == 0 or alcohol == stages.alcohol._1000_completed then
          options[6] = nil
        end

        local sigi = State.rails.quests.sigi
        if sigi == 0 or sigi == stages.sigi._1000_completed or State.player.bag.sigs == 0 then
          options[7] = nil
        end

        if not State.rails.did_markiss_help then
          options[8] = nil
        end
      end

      while true do
        local n = api.options(options, true)
        if n == 9 then break end
        table.insert(self._seen, n)
        sp:start_option(n)
          if n == 1 then
            sp:lines()
            sp:start_single_option()
              sp:lines()
            sp:finish_single_option()
            local m = sp:start_single_option()
              if m == 1 then
                sp:lines()
              else
                sp:lines()
                local o = sp:start_single_option()
                  if o == 1 then
                    sp:start_single_branch(State.player:ability_check("persuasion", 12) and 1 or 2)
                      sp:lines()
                    sp:finish_single_branch()
                  else
                    sp:lines()
                  end
                sp:finish_single_option()
              end
            sp:finish_single_option()

          elseif n == 2 then
            sp:lines()
            local m = sp:start_single_option()
            if m == 1 then
              sp:lines()
              local o = sp:start_single_option()
              if o == 1 then
                sp:lines()
              else
                sp:lines()
sp:start_single_branch(State.player:ability_check("wis", 14) and 1 or 2)
                  sp:lines()
                sp:finish_single_branch()
              end
              sp:finish_single_option()
              goto out
            end

            local skill, dc
            if m == 2 then
              skill = "religion"
              dc = 10
            else
              skill = "persuasion"
              dc = 12
            end
            sp:finish_single_option()

            local check = self._nature_check or State.player:ability_check(skill, dc)
            sp:start_single_branch(check and 1 or 2)
            local skill_subs = {SKILL = translation.skills[skill]:utf_capitalize()}
            if check then
              sp:lines(skill_subs)
              local suboptions = sp:start_options()
              local looped = true
              while looped do
                m = api.options(suboptions, true)
                sp:start_option(m)
                  if m == 1 then
                    sp:lines()
                  elseif m == 2 then
                    sp:lines()
                    local o = sp:start_single_option()
                    if o == 1 then
                      sp:lines({NAME = State.player.name})
                      ch.markiss.name = "Маркисс"
                      sp:lines()
                    else
                      sp:lines()
                    end
                    sp:finish_single_option()
                  else
                    looped = false
                  end
                sp:finish_option()
              end
              sp:finish_options()
            else
              sp:lines(skill_subs)
              sp:start_single_branch()
              if State.player:ability_check("nature", 10) then
                sp:lines()
              end
              sp:finish_single_branch()
              sp:lines()
            end
            sp:finish_single_branch()

          elseif n == 3 then
            sp:lines()
            -- SOUND horror SFX
            sp:lines()
            -- SOUND stop horror SFX
            sp:lines()

          elseif n == 4 then
            sp:lines()

          elseif n == 5 then
            sp:lines()

          elseif n == 6 then
            sp:lines()
            local m = sp:start_single_option()
            if m == 1 then
              sp:lines()
            else
              sp:start_single_branch(State.player:ability_check("intimidation", 12) and 1 or 2)
                Log.warn("TODO")
              sp:finish_single_branch()
            end
            sp:finish_single_option()

          elseif n == 7 then
            Log.warn("TODO")
          
          elseif n == 8 then
            sp:lines()
          end

        ::out::
        sp:finish_option()
      end
      sp:finish_options()
    end,
  },

  _402_markiss_hit = cutscene.make {
    enabled = true,
    mode = "sequential",
    characters = {
      markiss = {non_locking = true},
    },

    _on_add = function(self, ch, ps)
      self._sub = State.hostility:subscribe(function(source, target)
        if source == State.player and target == ch.markiss then
          self._trigger = true
        end
      end)
    end,

    _on_remove = function(self, ch, ps)
      State.hostility:unsubscribe(self._sub)
    end,

    _trigger = false,
    _condition = function(self, dt, ch, ps)
      return self._trigger
    end,

    _line_i = 0,
    _run = function(self, ch, ps)
      self._trigger = false
      if not self._lines then
        local sp = screenplay.new("assets/screenplay/402_markiss_hit.ms", ch)
        self._lines = {}
        while not sp:empty() do
          table.insert(self._lines, sp:literal())
        end
      end

      self._line_i = math.min(#self._lines, self._line_i + 1)
      State.model.popups = {}
      api.popup(self._lines[self._line_i], ch.markiss)
    end,
  },

  _410_captain_door = cutscene.make {
    enabled = true,
    mode = "sequential",
    screenplay = "assets/screenplay/410_captain_door.ms",
    characters = {
      player = {},
      captain_door_note = {},
      bridge_megadoor1 = {},
      bridge_megadoor2 = {},
      bridge_megadoor3 = {},
    },

    _on_add = function(self, ch, ps)
      item.set_cue(ch.captain_door_note, "highlight", true)
      interactive.mix_in(ch.captain_door_note)
    end,

    _condition = function(self, dt, ch, ps)
      return ch.captain_door_note.was_interacted_by == State.player
    end,

    _run = function(self, ch, ps, sp)
      sp:lines()
      State.rails.read_captain_door_note = true

      local options = sp:start_options()
      if self._tried_brute_force then
        options[2] = nil
      end
      if State.player.bag.valve == 0 then
        options[3] = nil
      end
      local hand = State.player.inventory.hand
      if not hand or hand.codename ~= "gas_key" then
        options[4] = nil
      end

      local looped = true
      while looped do
        local n = api.options(options, true)
        sp:start_option(n)
          if n == 1 then
            looped = false
          elseif n == 2 then
            State.player:animate("interact")
            sp:lines()
            local m = sp:start_single_option()
            if m == 1 then
              sp:lines()
            else
              local branch = State.player:ability_check("athletics", 18) and 1 or 2
              sp:start_single_branch(branch)
              if branch == 1 then
                State.player.inventory.hand = nil
                State.player:animate("holding", true, true)
                for _ = 1, 5 do
                  health.damage(State.player, 1, nil, true)
                  sp:lines()
                end
                State.player:animate()
                State.player.inventory.hand = hand
                ch.bridge_megadoor3._locked = false
                ch.bridge_megadoor3:on_interact(State.player)
                -- TODO iron jerry codex page
                looped = false
              else
                sp:lines()
              end
              sp:finish_single_branch()
            end
            sp:finish_single_option()
          elseif n == 3 then
            State:remove(ch.bridge_megadoor3)
            State:remove(ch.bridge_megadoor2)
            State:remove(ch.bridge_megadoor1)
            State.level.entities.bridge_megadoor3 = State:add_at(
              --- @diagnostic disable-next-line:undefined-field
              solids.megadoor3(), ch.bridge_megadoor3.position, "solids"
            )
            --- @diagnostic disable-next-line:undefined-field
            State:add_at(solids.megadoor2(), ch.bridge_megadoor2.position, "solids")
            --- @diagnostic disable-next-line:undefined-field
            State:add_at(solids.megadoor1(), ch.bridge_megadoor1.position, "solids")
            State.level.entities.bridge_megadoor3._locked = false
            State:remove(ch.captain_door_note)
            sp:lines()
            looped = false
          else
            State.player:animate("holding", true, true)
            sp:lines()
            State.player:animate()
            ch.bridge_megadoor3._locked = false
            ch.bridge_megadoor3:on_interact(State.player)
            sp:lines()
            looped = false
          end
        sp:finish_option()
      end

      sp:finish_options()
    end,
  },

  bridge_opens = cutscene.make {
    enabled = true,
    characters = {
      bridge_megadoor3 = {},
    },

    _condition = function(self, dt, ch, ps)
      return ch.bridge_megadoor3.grid_layer ~= "solids"
    end,

    _run = function(self, ch, ps, sp)
      api.order("Разблокируй желтый рычаг на правой панели")
      State.rails:set_quest("parasites", stages.parasites._0010_go_to_bridge)
    end,
  },

  _420_son_mary_swears = cutscene.make {
    enabled = true,
    mode = "sequential",
    screenplay = "assets/screenplay/420_son_mary_swears.ms",
    characters = {
      son_mary = {},
    },

    _prev_distance = 100,
    _condition = function(self, dt, ch, ps)
      local distance = api.distance(State.player, ch.son_mary)
      local result = not State.rails.met_son_mary
        and distance <= 3
        and self._prev_distance > 3
      self._prev_distance = distance
      return result
    end,

    _first_time = true,
    _run = function(self, ch, ps, sp)
      State.model.popups = {}
      local first_swear = sp:literal()
      if self._first_time then
        self._first_time = false
        api.popup(first_swear, ch.son_mary)
        return
      end

      api.popup(sp:literal(), ch.son_mary)
    end,
  },

  _422_son_mary_meeting = cutscene.make {
    enabled = true,
    mode = "sequential",
    screenplay = "assets/screenplay/422_son_mary_meeting.ms",
    characters = {
      player = {},
      son_mary = {},
      canteen_dreamer_flask = {dynamic = true, optional = true},
    },

    _condition = function(self, dt, ch, ps)
      if State.rails.quests.alcohol > 0 then
        State.runner:remove(self)
        return false
      end
      return ch.son_mary.was_interacted_by == State.player
    end,

    _first_time = true,
    _run = function(self, ch, ps, sp)
      State.model.popups = {}
      sp:start_single_branch()
      if self._first_time then
        self._first_time = false
        sp:lines()
        sp:start_single_branch(State.player:ability_check("medicine", 8) and 1 or 2)
          sp:lines()
        sp:finish_single_branch()
        sp:lines()
      end
      sp:finish_single_branch()

      local n = sp:start_single_option()
        sp:lines()
        if n == 4 then return end
      sp:finish_single_option()

      State.runner:remove(self)
      sp:lines()

      sound.new("assets/sounds/son_mary_spell.mp3"):play()
      sp:lines()

      n = State.player:saving_throw("wis", 18) and 1 or 2
      sp:start_single_branch(n)
      if n == 1 then
        -- TODO shader here
        -- SOUND
        sp:lines()
        State.rails.resists_son_mary = true
      else
        local this_mind_control = State:add(mind_control.new())
        sp:lines()
        local heartbeat = sound.new("assets/sounds/heartbeat.mp3")
        heartbeat:play()
        sp:lines()
        heartbeat:stop()
        sp:lines()
        State:remove(this_mind_control)
        sp:lines()
      end
      sp:finish_single_branch()

      sp:lines()

      api.order(sp:literal())
      async.sleep(2)

      sp:lines()

      sp:start_single_branch(State.player:ability_check("insight", 13) and 1 or 2)
        sp:lines()
      sp:finish_single_branch()

      sp:start_single_option()
        sp:lines()
      sp:finish_single_option()

      api.order(sp:literal())

      State.rails:set_quest("alcohol", stages.alcohol._0010_search)
      if State:exists(ch.canteen_dreamer_flask) then
        interactive.mix_in(ch.canteen_dreamer_flask)
      end
      api.autosave("Встретил Сон Мари")
    end,
  },

  _424_son_mary_no_alcohol = cutscene.make {
    enabled = true,
    mode = "sequential",
    characters = {
      son_mary = {},
    },

    _condition = function(self, dt, ch, ps)
      local alcohol = State.rails.quests.alcohol
      if alcohol == 0 then return false end
      if alcohol > stages.alcohol._0030_return then
        State.runner:remove(self)
        return false
      end
      return State.player.bag.alcohol == 0
        and ch.son_mary.was_interacted_by == State.player
    end,

    _lines = love.filesystem.read("assets/screenplay/424_son_mary_no_alcohol.txt")
      :strip()
      :split("\n"),
    _line_i = 0,
    _run = function(self, ch, ps, sp)
      self._line_i = Math.loopmod(self._line_i + 1, #self._lines)
      State.model.popups = {}
      api.popup(self._lines[self._line_i], ch.son_mary)
    end,
  },

  deck_fov_enter = cutscene.make {
    enabled = true,
    mode = "sequential",

    _condition = function(self, dt, ch, ps)
      return State.player.position.y == ps.water_fov_border_enter.y
        and State.player.fov_r ~= 30
    end,

    _run = function(self, ch, ps, sp)
      State.player.fov_r = 30
    end,
  },

  deck_fov_exit = cutscene.make {
    enabled = true,
    mode = "sequential",

    _condition = function(self, dt, ch, ps)
      return State.player.position.y == ps.water_fov_border_exit.y
        and State.player.fov_r ~= player_base.DEFAULT_FOV
    end,

    _run = function(self, ch, ps, sp)
      State.player.fov_r = player_base.DEFAULT_FOV
    end,
  },

  _442_furniture_room = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/442_furniture_room.ms",

    _condition = function(self, dt, ch, ps)
      return State.player.position == ps.furniture_room
    end,

    _run = function(self, ch, ps, sp)
      api.popup(sp:literal())
    end,
  },

  _444_furniture_room_fight = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/444_furniture_room_fight.ms",
    characters = {
      player = {},
    },

    _condition = function(self, dt, ch, ps)
      return State.player.position == ps.furniture_room_fight
    end,

    _run = function(self, ch, ps, sp)
      local check = State.player:saving_throw("con", 12)
      sp:start_single_branch(check and 1 or 2)
      if check then
        sp:lines()
      else
        sp:lines()
        local bfs = State.grids.solids:bfs(State.player.position)
        bfs()
        for _ = 1, 4 do ::redo::
          local p, e = bfs()
          if not p then break end
          if e then
            bfs:discard()
            goto redo
          else
            State:add_at(solids.bat(), p, "solids")
          end
        end
      end
      sp:finish_single_branch()
    end,
  },

  _452_razor = cutscene.make {
    enabled = true,
    mode = "sequential",
    screenplay = "assets/screenplay/452_razor.ms",
    characters = {
      player = {},
      dorm_woman = {},
      dorm_beard = {},
      dorm_grunt = {},
      dorm_halfling = {},
      razor = {dynamic = true},
    },

    _on_add = function(self, ch, ps)
      item.set_cue(ch.dorm_halfling, "highlight", true)
      interactive.mix_in(ch.dorm_halfling)
      local razor = State:add(items.razor())
      ch.dorm_halfling.inventory.inside = razor
      State.level.entities.razor = razor
    end,

    _condition = function(self, dt, ch, ps)
      return ch.dorm_halfling.was_interacted_by == State.player
    end,

    _seen = {},
    _run = function(self, ch, ps, sp)
      sp:lines()
      local options, option_3 do
        options = sp:start_options()
        for _, k in ipairs(self._seen) do
          options[k] = nil
        end
        if options[2] then
          option_3 = options[3]
          options[3] = nil
        end
      end

      while true do
        local n = api.options(options, true)
        if n == 4 then return end
        table.insert(self._seen, n)

        sp:start_option(n)
        if n == 1 then
          actions.move(Vector.up):_act(ch.dorm_woman)
          sp:lines()
        elseif n == 2 then
          sp:lines()
          options[3] = option_3
        else
          State.runner:remove(self)
          ch.dorm_halfling.interact = nil

          local check = State.player:ability_check("medicine", 12)
          sp:start_single_branch(check and 1 or 2)
          if check then
            sp:lines()

            api.curtain(.5, Vector.black):wait()
            local moved_characters = {"dorm_grunt", "dorm_woman"}
            local old_positions = {}
            for _, id in ipairs(moved_characters) do
              local p = ps[id.."_1"]
              if p then
                local e = ch[id]
                old_positions[e] = e.position
                level.slow_move(e, p)
              end
            end
            on_solids.fs.lie(ch.dorm_halfling, ps.dorm_bed, "lower")
            ch.dorm_halfling.ai = no_op.new()
            health.set_hp(ch.dorm_halfling, ch.dorm_halfling:get_max_hp())
            level.unsafe_move(State.player, ps.dorm_player)
            api.curtain(.5, Vector.transparent):wait()

            sp:lines()
            actions.move(Vector.right):_act(ch.dorm_woman)
            actions.move(Vector.left):_act(ch.dorm_grunt)

            api.curtain(.5, Vector.black):wait()
            for e, p in pairs(old_positions) do
              level.slow_move(e, p)
            end
            item.drop(ch.dorm_halfling, "inside")
            level.slow_move(ch.razor, ps.razor_drop)
            api.curtain(.5, Vector.transparent):wait()

            sp:lines()

            api.autosave("Полурослик вылечен")
          else
            sp:lines()
            local interacting = State.player:animate("interact")
            sp:lines()
            interacting:wait()
            health.damage(ch.dorm_grunt, 8, State.player, true)
            health.damage(ch.dorm_halfling, 10, State.player, true)
            sp:lines()
            State.hostility:set("dreamers_1", "player", "enemy")
            State:start_combat({State.player, ch.dorm_grunt})

            State.runner:run_task(function()
              coroutine.yield()
              while State.combat do
                coroutine.yield()
              end
              api.autosave("После драки в общежитии")
            end)
          end
          return
          sp:finish_single_branch()
        end
        sp:finish_option()
      end
      sp:finish_options()
    end,
  },
}
