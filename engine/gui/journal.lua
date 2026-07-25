local ui = require("engine.tech.ui")
local tk = require("engine.gui.tk")


local journal = {}

--- @class gui_journal
--- @field type "journal"
--- @field implementation table
--- @field _prev gui_game
local methods = {}
local mt = {__index = methods}

--- @param prev gui_game
--- @return gui_journal
journal.new = function(prev)
  local journal_new = State.player.journal_new
  if not journal_new then
    Error("No State.player.journal_new")
    State.runner:run_task(function() Kernel.gui:close_menu() end)
  end

  return setmetatable({
    type = "journal",
    implementation = journal_new(),
    _prev = prev,
  }, mt)
end

tk.delegate(methods, "draw_entity", "preprocess", "postprocess")

methods.draw_gui = function(self, dt)
  if ui.keyboard("escape") or ui.keyboard("j") then
    Kernel.gui:close_menu()
  end

  if ui.keyboard("n") then
    Kernel.gui:close_menu()
    Kernel.gui:open_menu("creator")
  end

  self.implementation:draw(dt)
end

Ldump.mark(journal, {}, ...)
return journal
