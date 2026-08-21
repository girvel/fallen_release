local actions = require("engine.mech.actions")
local xp = require("engine.mech.xp")
local solids = require("level.palette.solids")
local stages = require("level.logic.stages")
local sound = require("engine.tech.sound")
local animated = require("engine.tech.animated")
local colors = require("engine.tech.colors")
local floater = require("engine.tech.floater")
local interactive = require("engine.tech.interactive")
local async = require("engine.tech.async")
local health = require("engine.mech.health")
local shaders = require("level.shaders")
local on_solids = require("level.palette.on_solids")
local items = require("level.palette.items")
local item = require("engine.tech.item")
local cutscene = require("engine.tech.cutscene")
local api = require("engine.tech.api")


return {

----------------------------------------------------------------------------------------------------
-- [SECTION] Location scenes
----------------------------------------------------------------------------------------------------

  loc_201 = cutscene.make {
    enabled = true,

    _condition = function(self, dt, ch, ps)
      return State.player.position == ps.leaky_vent_check
    end,

    _run = function(self, ch, ps, sp)
      api.popup_check("investigation", 10,
        "Темные пятна на стенах и потолке могут указывать на проблемы с вентиляцией и серьезные утечки воды.",
        "Тёмные пятна на полу и потолке складываются в гротескные узоры."
      )
    end,
  },

  loc_202 = cutscene.make {
    enabled = true,

    _condition = function(self, dt, ch, ps)
      return State.player.position == ps.beds_check
    end,

    _run = function(self, ch, ps, sp)
      api.popup("Кровати плохо заправлены, будто это делали в одно движение.")
    end,
  },

  loc_204 = cutscene.make {
    enabled = true,

    _condition = function(self, dt, ch, ps)
      return State.player.position == ps.world_map_message
    end,

    _run = function(self, ch, ps, sp)
      api.popup("На стене висит старая мировая карта; тяжело различить хоть какой-то текст или даже очертания границ.")
    end,
  },

  loc_205 = cutscene.make {
    enabled = true,

    _condition = function(self, dt, ch, ps)
      return State.player.position == ps.scratched_table_message
    end,

    _run = function(self, ch, ps, sp)
      State.player:rotate(Vector.up)
      api.popup_check("investigation", 10,
        "Когда ты прищуриваешься, хаотичный узор из царапин на столе начинает напоминать тропический остров с пальмами, солнцем и счастливой семьей.",
        "Какой-то психопат порядочно поиздевался над столом."
      )
    end,
  },

  loc_206 = cutscene.make {
    enabled = true,

    _condition = function(self, dt, ch, ps)
      return State.player.position == ps.empty_dorm_message
    end,

    _run = function(self, ch, ps, sp)
      api.popup("Толстый слой пыли, отсутствие матраса и постельного белья. В этой комнате никто не живёт, очень давно.")
    end,
  },

  loc_207 = cutscene.make {
    enabled = true,

    _condition = function(self, dt, ch, ps)
      return api.distance(State.player, ps.sign_message) <= 2
    end,

    _run = function(self, ch, ps, sp)
      api.popup("Старый выцветший указатель. Налево — “столовая”, направо “-к*ю*-*омп*н*я”.", ps.sign_message)
    end,
  },

  loc_208 = cutscene.make {
    enabled = true,
    mode = "sequential",
    screenplay = "assets/screenplay/200_pipe.ms",
    characters = {
      player = {},
      colored_pipe = {},
    },

    _condition = function(self, dt, ch, ps)
      return ch.colored_pipe.was_interacted_by == State.player
    end,

    _run = function(self, ch, ps, sp)
      local n

      sp:lines()
      n = sp:start_single_option()
        if n ~= 1 then return end
        State.runner:remove(self)
        ch.colored_pipe.interact = nil
      sp:finish_single_option()

      n = State.player:ability_check("dex", 12) and 1 or 2
      sp:start_single_branch(n)
        if n == 1 then
          sp:lines()
          item.give(State.player, items.knife())
          sp:lines()
        else
          sp:lines()
          on_solids.fs.burst(ch.colored_pipe.position)
          sp:lines()
        end
      sp:finish_single_branch()
    end,
  },

  loc_209 = cutscene.make {
    enabled = true,
    characters = {
      player = {},
    },

    _condition = function(self, dt, ch, ps)
      return State.player.position == ps.mouse_check
    end,

    _run = function(self, ch, ps, sp)
      api.rotate(State.player, ps.mouse_check)
      api.line(nil, "Здесь повесилась мышь. Забавно.")
      api.popup_check("nature", 14,
        "Животные ощущают наш мир лучше, чем люди. Мышь, должно быть, предчувствовала что-то ужасное. Может, мне тоже начать бояться?",
        "У меня нет объяснений этому явлению."
      )
    end,
  },

  _210_latrine_warning = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/210_latrine_warning.ms",
    characters = {
      player = {},
    },

    _condition = function(self, dt, ch, ps)
      return State.player.position == ps.exit_latrine
    end,

    _run = function(self, ch, ps, sp)
      sp:lines()
    end,
  },

  _211_latrine_enter = cutscene.make {
    enabled = true,
    mode = "sequential",
    screenplay = "assets/screenplay/211_latrine_enter.ms",

    _condition = function(self, dt, ch, ps)
      return State.player.position == ps.enter_latrine
        and not State.rails.in_latrine
    end,

    _first_time = true,
    _run = function(self, ch, ps, sp)
      State.rails.in_latrine = true
      State.runner:cancel("_212_latrine_exit", true)

      if self._first_time then
        self._first_time = false
        State.rails.tolerates_latrine = State.player:saving_throw("con", 14)
        api.lock(State.player)
          sp:start_single_branch(State.rails.tolerates_latrine and 1 or 2)
            sp:lines()
          sp:finish_single_branch()
        api.unlock(State.player)
      end

      if State.rails.tolerates_latrine then
        State.rails.player_last_fov = State.player.fov_r
        State.player.fov_r = 1
      else
        State.shader = shaders.latrine
      end
    end,
  },

  _212_latrine_exit = cutscene.make {
    enabled = true,
    mode = "sequential",
    screenplay = "assets/screenplay/212_latrine_exit.ms",

    _condition = function(self, dt, ch, ps)
      return State.player.position == ps.exit_latrine
        and State.rails.in_latrine
    end,

    _first_time = true,
    _run = function(self, ch, ps, sp)
      State.rails.in_latrine = false
      State.runner:cancel("_211_latrine_enter")

      if State.rails.tolerates_latrine then
        State.player.fov_r = assert(State.rails.player_last_fov)
        State.rails.player_last_fov = nil
      else
        if self._first_time then
          self._first_time = false
          api.lock(State.player)
            sp:lines()
            health.damage(State.player, 1)
            sp:lines()
          api.unlock(State.player)
        else
          health.damage(State.player, 1)
        end

        async.sleep(10)
        State.shader = nil
      end
    end,

    _on_cancel = function()
      State.shader = nil
    end,
  },

  _213_dirty_magazine = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/213_dirty_magazine.ms",
    characters = {
      player = {},
      dirty_magazine = {},
    },

    _on_add = function(self, ch, ps)
      interactive.mix_in(ch.dirty_magazine)
      item.set_cue(ch.dirty_magazine, "highlight", true)
      ch.dirty_magazine.name = "Яркий журнал"
    end,

    _condition = function(self, dt, ch, ps)
      return ch.dirty_magazine.was_interacted_by == State.player
    end,

    _run = function(self, ch, ps, sp)
      ch.dirty_magazine.interact = nil
      sp:lines()
      sp:start_single_branch(State.player:ability_check("religion", 8) and 1 or 2)
        sp:lines()
      sp:finish_single_branch()
    end,
  },

  _220_kitchen_bucket = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/220_kitchen_bucket.ms",
    characters = {
      player = {},
    },

    _condition = function(self, dt, ch, ps)
      return api.distance(State.player, ps.kitchen_bucket) == 1
    end,

    _run = function(self, ch, ps, sp)
      sp:lines()
      sp:start_single_branch(State.player:ability_check("history", 10) and 1 or 2)
        sp:lines()
      sp:finish_single_branch()
    end,
  },

  _221_cook = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/221_cook.ms",
    characters = {
      player = {},
      cook = {},
      soup_cauldron = {},
    },

    _on_add = function(self, ch, ps)
      ch.cook:rotate(Vector.up)
    end,

    _condition = function(self, dt, ch, ps)
      return api.distance(ch.cook, ch.soup_cauldron) == 1
        and ch.cook.was_interacted_by == State.player
    end,

    _run = function(self, ch, ps, sp)
      ch.cook.interact = nil

      sp:lines()
      api.rotate(ch.cook, State.player)
      sp:lines()
      local n = State.player:ability_check("cha", 14) and 1 or 2
      sp:start_single_branch(n)
      if n == 1 then
        sp:lines()

        local d = math.max(1, State.player:get_modifier("con"))
        State:add(floater.new("+"..d, State.player.position, colors.light_green))
        health.set_hp(State.player, State.player.hp + d)
        ch.cook:rotate(Vector.up)
        sp:lines()
      else
        ch.cook:rotate(Vector.up)
        sp:lines()
      end
      sp:finish_single_branch()
    end,
  },

  _222_cauldron = cutscene.make {
    enabled = true,
    characters = {
      soup_cauldron = {},
    },

    _on_add = function(self, ch, ps)
      interactive.mix_in(ch.soup_cauldron)
      ch.soup_cauldron.name = "котелок"
    end,

    _condition = function(self, dt, ch, ps)
      return ch.soup_cauldron.was_interacted_by == State.player
    end,

    _run = function(self, ch, ps, sp)
      ch.soup_cauldron.interact = nil
      api.popup("Кажется, у меня пропал аппетит", ch.soup_cauldron)
    end,
  },

  _disappearing_dude = cutscene.make {
    enabled = true,
    characters = {
      dining_room_door_1 = {optional = true},
      dining_room_door_2 = {optional = true},
    },

    _condition = function(self, dt, ch, ps)
      if State.rails.quests.warmup >= stages.warmup._1000_bird_fed then
        State.runner:remove(self)
        return false
      end

      return not State:exists(ch.dining_room_door_1)
        or not State:exists(ch.dining_room_door_2)
    end,

    _run = function(self, ch, ps, sp)
      animated.add_fx("assets/animations/disappearing_dude", ps.possessed_image, "on2_solids")
      sound.new("assets/sounds/creepy.mp3", .1):play()
    end,
  },

  _230_engine = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/230_engine.ms",

    _condition = function(self, dt, ch, ps)
      return State.player.position >= ps.engine_message_start
        and State.player.position <= ps.engine_message_finish
    end,

    _run = function(self, ch, ps, sp)
      sp:start_single_branch(State.player:ability_check("history", 16) and 1 or 2)
        api.popup(sp:literal())
      sp:finish_single_branch()
    end,
  },

  _232_engine_attacked = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/232_engine_attacked.ms",

    _on_add = function(self, ch, ps)
      self._sub = State.hostility:subscribe(function(source, target)
        if source == State.player and target._left_engine_flag then
          self._triggered = true
        end
      end)
    end,

    _on_remove = function(self, ch, ps)
      State.hostility:unsubscribe(self._sub)
    end,

    _triggered = false,
    _condition = function(self, dt, ch, ps)
      return self._triggered
    end,

    _run = function(self, ch, ps, sp)
      self._triggered = false
      api.popup(sp:literal())
    end,
  },

  _234_engine_dreamers = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/234_engine_dreamers.ms",
    characters = {
      protected_1 = {},
      protected_2 = {},
      protected_3 = {},
      player = {},
    },

    _condition = function(self, dt, ch, ps)
      return ch.protected_1.was_interacted_by == State.player
        or ch.protected_2.was_interacted_by == State.player
        or ch.protected_3.was_interacted_by == State.player
    end,

    _run = function(self, ch, ps, sp)
      ch.protected_1.interact = nil
      ch.protected_2.interact = nil
      ch.protected_3.interact = nil
      sp:lines()
    end,
  },

  _260_guard_a_talking = cutscene.make {
    enabled = true,
    mode = "sequential",
    screenplay = "assets/screenplay/260_guard_a_talking.ms",
    characters = {
      player = {},
      guard_a = {},
    },

    _condition = function(self, dt, ch, ps)
      if State.hostility:get(ch.guard_a, State.player) == "enemy" then
        State.runner:remove(self)
        return false
      end
      return ch.guard_a.was_interacted_by == State.player
    end,

    _run = function(self, ch, ps, sp)
      sp:lines()
    end,
  },

  _guard_a_rotates = cutscene.make {
    enabled = true,
    mode = "sequential",
    characters = {
      guard_a = {non_locking = true},
    },

    _t = 0,
    _condition = function(self, dt, ch, ps)
      if State.runner:is_running("_272_rum") then
        return false
      end

      self._t = self._t + dt
      if self._t >= 8 then
        self._t = self._t - 8
        return true
      end
      return false
    end,

    _run = function(self, ch, ps, sp)
      ch.guard_a:rotate(Vector.down)
      local t = 0
      while t < 1 or State.runner:is_running("_272_rum") do
        t = t + coroutine.yield()
      end
      ch.guard_a:rotate(Vector.left)
    end,
  },

  _266_storage_container_1 = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/266_storage_container_1.ms",
    characters = {
      storage_container_1 = {},
    },

    _on_add = function(self, ch, ps)
      self._on_interact = ch.storage_container_1.on_interact
      ch.storage_container_1.on_interact = nil
    end,

    _condition = function(self, dt, ch, ps)
      return ch.storage_container_1.was_interacted_by == State.player
    end,

    _run = function(self, ch, ps, sp)
      self._on_interact(ch.storage_container_1, State.player)
      api.popup(sp:literal(), ch.storage_container_1)
    end,
  },

  _268_storage_container_2 = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/268_storage_container_2.ms",
    characters = {
      storage_container_2 = {},
    },

    _on_add = function(self, ch, ps)
      self._on_interact = ch.storage_container_2.on_interact
      ch.storage_container_2.on_interact = nil
    end,

    _condition = function(self, dt, ch, ps)
      return ch.storage_container_2.was_interacted_by == State.player
    end,

    _run = function(self, ch, ps, sp)
      self._on_interact(ch.storage_container_2, State.player)
      api.popup(sp:literal(), ch.storage_container_2)
    end,
  },

  _270_storage_container_3 = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/270_storage_container_3.ms",
    characters = {
      storage_container_3 = {},
    },

    _on_add = function(self, ch, ps)
      self._on_interact = ch.storage_container_3.on_interact
      ch.storage_container_3.on_interact = nil
    end,

    _condition = function(self, dt, ch, ps)
      return ch.storage_container_3.was_interacted_by == State.player
    end,

    _run = function(self, ch, ps, sp)
      self._on_interact(ch.storage_container_3, State.player)
      api.popup(sp:literal(), ch.storage_container_3)
    end,
  },

  _272_rum = cutscene.make {
    enabled = true,
    mode = "sequential",
    screenplay = "assets/screenplay/272_rum.ms",
    characters = {
      player = {},
      alcohol_crate = {},
      guard_a = {optional = true},
      guard_b = {optional = true},
    },

    _on_add = function(self, ch, ps)
      self._on_interact = ch.alcohol_crate.on_interact
      ch.alcohol_crate.on_interact = nil
    end,

    _condition = function(self, dt, ch, ps)
      return ch.alcohol_crate.was_interacted_by == State.player
    end,

    _attempt_i = 0,
    _intro = true,
    _run = function(self, ch, ps, sp)
      local finish = function()
        State.rails:alcohol_pick_up("rum")
        self._on_interact(ch.alcohol_crate, State.player)
        State.runner:remove(self)
      end

      if not State:exists(ch.guard_a) then
        finish()
        return
      end

      sp:start_branches()
      if ch.guard_a.direction == Vector.left then
        self._attempt_i = self._attempt_i + 1
        sp:start_branch(self._attempt_i)
          sp:lines()
          if self._attempt_i == 3 then
            State.hostility:set("guards", "player", "enemy")
            State:start_combat({State.player, ch.guard_a, ch.guard_b})
          end
        sp:finish_branch()
        return
      end
      sp:finish_branches()

      sp:start_single_branch()
      if self._intro then
        self._intro = false
        sp:lines()
        sp:start_single_branch(State.rails.quests.alcohol == 0 and 1 or 2)
          sp:lines()
        sp:finish_single_branch()
      end
      sp:finish_single_branch()

      local fail_the_check = function()
        actions.move(Vector.right):_act(State.player)
        sp:lines()

        api.rotate(ch.guard_a, State.player)
        api.rotate(ch.guard_b, State.player)
        sp:lines()

        State.hostility:set("guards", "player", "enemy")
        State:start_combat({State.player, ch.guard_a, ch.guard_b})
      end

      local n = sp:start_single_option()
      if n == 1 then
        sp:lines()
        return
      elseif n == 2 then
        local check = State.player:ability_check("cha", 18)
        sp:start_single_branch(check and 1 or 2)
        if check then
          finish()

          ch.guard_a:rotate(Vector.left)
          api.popup(sp:literal(), ch.guard_a)
          sp:lines()

          api.rotate(State.player, ch.guard_a)
          sp:lines()

          State.player:rotate(Vector.down)
          State.player:animate("interact")
          State.runner:run_task(function()
            async.sleep(.3)
            ch.guard_a:rotate(Vector.down)
          end)
          sp:lines()

          api.rotate(State.player, ch.guard_a)
          sp:lines()
          api.autosave("Ром заполучен")
        else
          fail_the_check()
        end
        sp:finish_single_branch()
      else
        local check = State.player:ability_check("perception", 12)
        sp:start_single_branch(check and 1 or 2)
        if check then
          finish()

          sp:lines()

          actions.move(Vector.right):_act(State.player)
          sp:lines()

          local go_out = api.travel_scripted(State.player, ps.storage_room_exit)
          sp:lines()
          go_out:wait()
          api.autosave("Ром заполучен")
        else
          fail_the_check()
        end
        sp:finish_single_branch()
      end
      sp:finish_single_option()
    end,
  },

  _274_guard_b = cutscene.make {
    enabled = true,
    mode = "sequential",
    screenplay = "assets/screenplay/274_guard_b.ms",
    characters = {
      guard_b = {},
      player = {},
    },

    _condition = function(self, dt, ch, ps)
      return ch.guard_b.was_interacted_by == State.player
    end,

    _seen = {},
    _run = function(self, ch, ps, sp)
      sp:lines()

      local options do
        options = sp:start_options()
        for _, key in ipairs(self._seen) do
          options[key] = nil
        end

        if not State.rails.read_captain_door_note then
          options[2] = nil
          options[3] = nil
        else
          if State.rails.quests.parasites == stages.parasites._0010_go_to_bridge then
            options[3] = nil
          else
            options[2] = nil
          end
        end

        if State.rails.quests.alcohol == 0
          or State.rails.quests.alcohol == stages.alcohol._1000_completed
        then
          options[4] = nil
        end
      end

      while true do
        local n = api.options(options, true)
        if n == 5 then break end
        table.insert(self._seen, n)
        sp:start_option(n)
        if n == 1 then
          sp:lines()
          sp:start_single_branch(State.player:ability_check("history", 8) and 1 or 2)
            sp:lines()  -- TODO SFX/SOUND for branch 2
          sp:finish_single_branch()
        elseif n == 2 then
          ch.guard_b:animate("interact"):next(function()
            State.rails:get_valve()
          end)
          sp:lines()
          local check = State.player:ability_check("insight", 12)
          sp:start_single_branch(check and 1 or 2)
            if check then
              sp:lines()
            else
              sp:lines()
              State.player:rotate((State.player.position - ch.guard_b.position):normalized2())
              sp:lines()
            end
          sp:finish_single_branch()
          return
        elseif n == 3 then
          sp:lines()
          local m = sp:start_single_option()
            if m == 2 then
              sp:finish_single_option()
              goto continue
            end

            sp:lines()
            local check = State.player:ability_check("intimidation", 12)
            sp:start_single_branch(check and 1 or 2)
            if check then
              sp:lines()
              ch.guard_b:animate("interact"):next(function()
                State.rails:get_valve()
              end)
              sp:lines()
            else
              sp:lines()
              api.order(sp:literal())
              sp:lines()
              State.hostility:set("guards", "player", "enemy")
            end
            sp:finish_single_branch()
          sp:finish_single_option()
          return
        else
          sp:lines()
        end

        ::continue::
        sp:finish_option()
      end

      sp:finish_options()
    end,
  },

----------------------------------------------------------------------------------------------------
-- [SECTION] Story scenes
----------------------------------------------------------------------------------------------------

  _240_entering_officer_room = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/240_entering_officer_room.ms",

    _condition = function(self, dt, ch, ps)
      return State.player.position == ps.officer_room_enter
    end,

    _run = function(self, ch, ps, sp)
      api.order(sp:literal())
      State.rails:set_quest("warmup", stages.warmup._0040_in_room)
      State.rails.fighting_guide_status = "seen"
    end,
  },

  _241_note_picked_up = cutscene.make {
    enabled = true,
    characters = {
      fighting_guide = {},
    },

    _on_add = function(self, ch, ps)
      item.set_cue(ch.fighting_guide, "highlight", true)
      interactive.mix_in(ch.fighting_guide)
      ch.fighting_guide.name = "брошюра"
    end,

    _condition = function(self, dt, ch, ps)
      return ch.fighting_guide.was_interacted_by == State.player
    end,

    _run = function(self, ch, ps, sp)
      State:remove(ch.fighting_guide)
      State.rails.fighting_guide_status = "picked_up"
    end,
  },

  -- mannequin_safety = {
  --   condition = function(self, name, dt)
  --     if State.rails.quests.warmup >= stages.warmup._0060_practiced then
  --       State:remove(self)
  --       return false
  --     end
  --     return not State:exists(State.level.entities.mannequin)
  --   end,

  --   run = function(self, name)
  --     State.rails:set_quest("warmup", stages.warmup._0060_practiced)
  --   end,
  -- },

  _242_weapon_picked_up = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/242_weapon_picked_up.ms",
    characters = {
      mannequin = {},
      mirage_block = {non_locking = true},
    },

    _condition = function(self, dt, ch, ps)
      return State.player.inventory.hand
        and State.rails.quests.warmup < stages.warmup._0050_weapon_picked_up
    end,

    _run = function(self, ch, ps, sp)
      local old_hp = ch.mannequin.hp
      api.order(sp:literal())
      State.rails:set_quest("warmup", stages.warmup._0050_weapon_picked_up)

      local suggestion = sp:literal()
      local _, suggestion_scene = State.runner:run_task(function()
        while State.rails.quests.warmup < stages.warmup._0060_practiced
          and State:exists(ch.mannequin)
        do
          if api.distance(State.player, ch.mannequin) == 1
            and State.player.direction == ch.mannequin.position - State.player.position
          then
            State.model.suggestion = suggestion
          else
            State.model.suggestion = nil
          end
          coroutine.yield()
        end
        State.model.suggestion = nil
      end, "mannequin_suggestion")
      suggestion_scene.on_cancel = function()
        State.model.suggestion = nil
      end

      local miss_remark = sp:literal()
      local remarks = {
        sp:literal(),
        sp:literal(),
        sp:literal(),
      }

      local miss_remarked = false
      self._sub = State.hostility:subscribe(function(source, target)
        if source == State.player and target == ch.mannequin then
          if ch.mannequin.hp < old_hp then
            old_hp = ch.mannequin.hp
            api.order(table.remove(remarks, 1))
          elseif not miss_remarked then
            miss_remarked = true
            api.order(miss_remark)
          end
        end
      end)

      while State:exists(ch.mannequin) and #remarks > 0 do
        coroutine.yield()
      end
      State.runner:cancel(suggestion_scene)

      async.sleep(3)
      api.order(sp:literal())
      State.rails:set_quest("warmup", stages.warmup._0060_practiced)
      if not State.runner:is_running("_244_phantom") then
        item.set_cue(ch.mirage_block, "highlight", true)
      end
      State.hostility:unsubscribe(self._sub)
    end,

    _on_cancel = function(self)
      if self._sub then
        State.hostility:unsubscribe(self._sub)
      end
      State.rails:set_quest("warmup", stages.warmup._0060_practiced)
    end,
  },

  _244_phantom = cutscene.make {
    enabled = true,
    mode = "sequential",
    screenplay = "assets/screenplay/244_phantom.ms",
    characters = {
      player = {},
      mirage_block = {},
      bird_cage = {},
      bird_food = {},
    },

    _on_add = function(self, ch, ps)
      interactive.mix_in(ch.mirage_block)
      ch.mirage_block.name = "Блок миража"
    end,

    _condition = function(self, dt, ch, ps)
      return ch.mirage_block.was_interacted_by == State.player
    end,

    _run = function(self, ch, ps, sp)
      sp:lines()

      local phantom
      local options = sp:start_options()
      local running = true
      while running do
        local n = api.options(options)
        sp:start_option(n)
          if n == 1 then
            sp:lines()
          elseif n == 2 then
            sp:lines()

            animated.add_fx("assets/animations/mirage_spawn", ps.officer_room_enter, "fx_under")
            async.sleep(.5)
            sound.new("assets/sounds/phantom_appearing.mp3", .1):play()
            phantom = State:add_at(solids.phantom(), ps.officer_room_enter, "solids")
            sp:lines()

            sp:start_single_branch(State.player:ability_check("arcana", 10) and 1 or 2)
              sp:lines()
            sp:finish_single_branch()
            State.runner:remove(self)
            State.runner:cancel("_242_weapon_picked_up")
            ch.mirage_block.interact = nil
            running = false
          else
            return
          end
        sp:finish_option()
      end
      sp:finish_options()

      api.unlock(State.player)
      State:start_combat({State.player, phantom})

      while not State.combat do coroutine.yield() end
      api.popup(sp:literal())

      local move_order = sp:literal()
      State.runner:run_task(function()
        async.sleep(2)
        api.order(move_order)
      end)

      local pass_turn_suggestion = sp:literal()
      while State.combat:get_current() == State.player do
        if State.player.resources.movement == 0 then
          State.model.suggestion = pass_turn_suggestion
        else
          State.model.suggestion = nil
        end
        coroutine.yield()
      end
      State.model.suggestion = nil

      local attack_suggestion = sp:literal()
      local _, attack_suggestion_sc = State.runner:run_task(function()
        while State.combat do
          if api.distance(State.player, phantom) == 1
            and State.player.resources.actions > 0
            and State.combat:get_current() == State.player
          then
            State.model.suggestion = attack_suggestion
          else
            State.model.suggestion = nil
          end
          coroutine.yield()
        end
      end, "attack_suggestion")

      local illusion_popup = sp:literal()
      local kill_order = sp:literal()
      local sub
      sub = State.hostility:subscribe(function(source, target)
        if source == phantom and target == State.player then
          State.hostility:unsubscribe(sub)
          api.popup(illusion_popup, phantom)
          State.runner:run_task(function()
            async.sleep(5)
            api.order(kill_order)
          end)
        end
      end)

      while State.combat do coroutine.yield() end
      api.order(sp:literal())
      State.rails:set_quest("warmup", stages.warmup._0070_mirage_defeated)

      interactive.mix_in(ch.bird_cage)
      ch.bird_cage.name = "клетка"
      item.set_cue(ch.bird_cage, "highlight", true)

      interactive.mix_in(ch.bird_food)
      item.set_cue(ch.bird_food, "highlight", true)

      State.model.suggestion = nil
      State.hostility:unsubscribe(sub)
      State:remove(attack_suggestion_sc)
    end,
  },

  _246_crate = cutscene.make {
    enabled = true,
    mode = "sequential",
    screenplay = "assets/screenplay/246_crate.ms",
    characters = {
      player = {},
      bird_food = {},
    },

    _on_add = function(self, ch, ps)
      ch.bird_food.interact = nil
        -- disables default crate's interact
    end,

    _condition = function(self, dt, ch, ps)
      return State.rails.quests.warmup == stages.warmup._0070_mirage_defeated
        and ch.bird_food.was_interacted_by == State.player
    end,

    _run = function(self, ch, ps, sp)
      sp:lines()
      local options = sp:start_options()
      while true do
        local n = api.options(options, true)
        if n == 1 then
          State.runner:remove(self)
          State.player.bag.bird_food = 1
          ch.bird_food.interact = nil
        else
          break
        end
      end
      sp:finish_options()
    end,
  },

  _248_cage = cutscene.make {
    enabled = true,
    mode = "sequential",
    screenplay = "assets/screenplay/248_cage.ms",
    characters = {
      player = {},
      bird_cage = {},
      detective_door = {},
    },

    _condition = function(self, dt, ch, ps)
      return State.rails.quests.warmup == stages.warmup._0070_mirage_defeated
        and ch.bird_cage.was_interacted_by == State.player
    end,

    _run = function(self, ch, ps, sp)
      sp:lines()

      local options = sp:start_options()
      if State.player.bag.bird_food == 0 then
        options[1] = nil
      end
      while true do
        local n = api.options(options, true)
        if n == 1 then
          State:remove(self)
          ch.bird_cage.interact = nil
          State.player.bag.bird_food = 0
          State.rails:set_quest("warmup", stages.warmup._1000_bird_fed)
          State.rails:transition_3_detective()
        else
          break
        end
      end
      sp:finish_options()

      if State.rails.quests.warmup < stages.warmup._1000_bird_fed then return end

      sp:lines()

      State.rails:set_quest("detective", stages.detective._0010_black_door)
      api.order(sp:literal())
      api.autosave(sp:literal())
    end,
  },

  _250_possessed = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/250_possessed.ms",
    characters = {
      possessed = {dynamic = true},
      player = {},
    },

    _condition = function(self, dt, ch, ps)
      if State.rails.lunch_started then
        State.runner:remove(self)
        return false
      end
      return api.distance(State.player, ch.possessed) < 5
    end,

    _run = function(self, ch, ps, sp)
      sp:lines()
      sound.new("assets/sounds/possessed_turns_around.mp3", .15):play()
      api.rotate(ch.possessed, State.player)
      sp:lines()
      State:start_combat({State.player, ch.possessed})
      ch.possessed.ai.starts_no_fights = false
    end,
  },

  _252_possessed_killed = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/252_possessed_killed.ms",
    characters = {
      player = {},
      possessed = {dynamic = true, optional = true},
      bird_cage = {},
    },

    _condition = function(self, dt, ch, ps)
      if State.rails.lunch_started then
        State.runner:remove(self)
        return false
      end
      local possessed = rawget(ch, "possessed")
      return possessed and possessed.hp <= 0
        and State.rails.quests.detective < stages.detective._1000_completed
    end,

    _run = function(self, ch, ps, sp)
      sp:lines()
      local options = sp:start_options()
      local loop = true
      while loop do
        local n = api.options(options, true)
        sp:start_option(n)
        if n == 1 then
          sp:start_single_branch(State.player:ability_check("medicine", 12) and 1 or 2)
            sp:lines()
          sp:finish_single_branch()
        elseif n == 2 then
          State.player.bag.bird_remains = 1
          interactive.mix_in(ch.bird_cage)
          item.set_cue(ch.bird_cage, "highlight", true)
        else
          loop = false
        end
        sp:finish_option()
      end
      sp:finish_options()
    end,
  },

  _254_bird_remains = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/254_bird_remains.ms",
    characters = {
      player = {},
      bird_cage = {},
    },

    _condition = function(self, dt, ch, ps)
      return ch.bird_cage.was_interacted_by == State.player
        and State.player.bag.bird_remains > 0
    end,

    _run = function(self, ch, ps, sp)
      sp:lines()
      State.player.bag.bird_remains = 0
      ch.bird_cage.interact = nil
      xp.reward(State.player, 10)
    end,
  }
}
