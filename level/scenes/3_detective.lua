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
      self._condition_t = self._condition_t - dt
      local trigger = self._condition_t <= 0
      if trigger then
        self._condition_t = Random.float(30, 40)
      end
      return trigger
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
      end

      local text = choices[n]:gsub("{[^}]*}", suffix)
      api.popup(text, ch.engineer_1)
    end,
  },

  _304_room_description = cutscene.make {
    enabled = true,
    screenplay = "assets/screenplay/304_room_description.ms",
    characters = {
      
    },

    _condition = function(self, dt, ch, ps)
      return 
    end,

    _run = function(self, ch, ps, sp)
      
    end,
  },
}
