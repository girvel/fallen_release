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
}
