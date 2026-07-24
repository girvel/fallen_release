local sound = require("engine.tech.sound")
local health = require("engine.mech.health")
local interactive = require("engine.tech.interactive")
local animated = require("engine.tech.animated")
local sprite = require("engine.tech.sprite")
local reflective = require("level.shaders.reflective")
local factoring = require("engine.tech.factoring")


local on_solids = {}

----------------------------------------------------------------------------------------------------
-- [SECTION] Atlas
----------------------------------------------------------------------------------------------------

on_solids.ATLAS_IMAGE = love.graphics.newImage("assets/atlases/on_solids.png")
local packer = factoring.packer(on_solids.ATLAS_IMAGE)

packer.offset = 0
do
  local i, this_sprite = packer:get(1, 1)
  on_solids[i] = function()
    return {
      boring_flag = true,
      perspective_flag = true,
      codename = "mirror",
      sprite = this_sprite,
      shader = reflective(Vector.down * 2),
    }
  end
end

do
  local i, this_sprite = packer:get(6, 3)
  on_solids[i] = function()
    return {
      boring_flag = true,
      codename = "son_mary_bottom",
      name = "Голова в банке",
      sprite = this_sprite,
      portrait = sprite.image("assets/portraits/son_mary.png"),
    }
  end
end

for _, tuple in ipairs {
  {2, "grime"},
  {3, "airway", true},
  {4, "map", true},
  {5, "sign"},
  {6, "window"},
  {7, "upper_bunk", true},
  {8, "cauldron", true},
  {9, "vines"},
  {10, "vines"},
  {11, "vines"},
  {12, "vines"},
  {13, "vines"},
  {14, "son_mary_top"},
  {15, "blood", true},
  {16, "cauldron", true},
  {17, "vines"},
  {18, "vines"},
  {19, "vines"},
  {20, "vines"},
  {21, "vines"},
  {23, "helm"},
  {24, "inscription"},
  {25, "door_open"},
  {26, "door_open"},
  {27, "door_broken"},
  {28, "vines"},
  {29, "vines"},
  {30, "note"},
  {33, "vines"},
  {34, "vines"},
  {35, "vines"},
  {36, "vines"},
  {37, "vines"},
  {41, "engine"},
  {42, "engine"},
  {43, "engine"},
  {44, "engine"},
  {49, "engine"},
  {50, "engine"},
  {51, "engine"},
  {57, "engine"},
  {58, "engine"},
  {59, "engine"},
  {65, "plate"},
  {66, "plate"},
  {67, "plate"},
  {68, "plate"},
  {73, "vase"},
  {74, "vase"},
  {75, "vase"},
  {76, "candle"},
  {77, "candle"},
  {78, "candle"},
  {81, "vase"},
  {82, "vase"},
  {83, "vase"},
  {89, "skull"},
  {90, "bones"},
  {91, "bones"},
  {92, "bones"},
  {93, "bone_meal"},
  {94, "bone_meal"},
} do
  local index, codename, perspective_flag = unpack(
    tuple --[=[@as [integer, string, true?]]=]
  )
  local i, this_sprite = packer:geti(index)
  on_solids[i] = function()
    return {
      boring_flag = true,
      perspective_flag = perspective_flag,
      codename = codename,
      sprite = this_sprite,
    }
  end
end

local collect_food = function(self, other)
  State:remove(self)
  State:add_at(on_solids[Random.choice(65, 66, 67, 68)](), self.position, "on_solids")
  health.heal(other, 1)
end

packer.offset = 64
for _, tuple in ipairs {
  {5, "food", "пища"},
  {6, "food", "пища"},
  {7, "food", "пища"},
  {20, "beer", "кружка с пивом"},
  {22, "wine", "бутылка вина"},
} do
  local index, codename, name = unpack(
    tuple --[=[@as [integer, string, string]]=]
  )
  local i, this_sprite = packer:geti(index)
  on_solids[i] = function()
    local e = {
      boring_flag = true,
      codename = codename,
      name = name,
      sprite = this_sprite
    }
    interactive.mix_in(e, collect_food)
    return e
  end
end

do
  local i, this_sprite = packer:get(5, 3)
  on_solids[i] = function()
    local e = {
      boring_flag = true,
      codename = "newspaper",
      name = "газета",
      sprite = this_sprite
    }
    interactive.mix_in(e)
    return e
  end
end

----------------------------------------------------------------------------------------------------
-- [SECTION] Entities
----------------------------------------------------------------------------------------------------

local valve_rotation_sounds = sound.multiple("assets/sounds/pipe_valve/rotate", .05)

on_solids.pipe_valve = function(steam_source_pos)
  local e = {
    codename = "pipe_valve",
    name = "Вентиль",
    boring_flag = true,

    on_add = function(self)
      self._steam_source = State.grids.on_solids:slow_get(steam_source_pos)
      if not self._steam_source then
        Error("No on_solids.steam_source at %s", steam_source_pos)
      end
    end,
  }
  animated.mix_in(e, "assets/animations/pipe_valve/", "no_atlas")
  interactive.mix_in(e, function(self)
    valve_rotation_sounds:play_at(self.position)
    self:animate("rotate"):next(function()
      if not self._steam_source then return end
      self._steam_source:_burst()
      self._steam_source._overflow = 0
    end)
  end)
  return e
end

local pipe_overflow_sound = sound.new("assets/sounds/pipe_overflow.wav"):set_looping(true)
local pipe_burst_sounds = sound.multiple("assets/sounds/steam_hissing", .8)

on_solids.steam_source = function()
  return {
    codename = "steam_source",
    boring_flag = true,

    _burst = function(self)
      local fx = animated.add_fx("assets/animations/steam/", self.position, "fx_over")
      pipe_burst_sounds:play_at(self.position)
      State.runner:run_task(function()
        local damaged = {}
        while State:exists(fx) do
          local e = State.grids.solids:slow_get(self.position + Vector.right)
          if fx.animation.frame > 2 and e and e.hp and not damaged[e] then
            health.attack_save(self, e, "dex", 15, 1)
            damaged[e] = true
          end
          coroutine.yield()
        end
      end, "steam_damage")
    end,

    _paused = false,
    _overflow = 0,
    _overflow_leak = 0,

    ai = {
      observe = function(self, entity, dt)
        if entity._paused then return end
        entity._overflow = entity._overflow + dt
        if entity._overflow >= 60 then
          if not self._overflow_sound then
            self._overflow_sound = pipe_overflow_sound
              :clone()
              :place(entity.position)
              :play()
          end
          entity._overflow_leak = entity._overflow_leak + dt
          while entity._overflow_leak > 1 do
            entity._overflow_leak = entity._overflow_leak - 1
            entity:_burst()
          end
          return
        end

        if self._overflow_sound then
          self._overflow_sound:stop()
          self._overflow_sound = nil
        end
      end,
    },
  }
end

Ldump.mark(on_solids, {}, ...)
return on_solids
