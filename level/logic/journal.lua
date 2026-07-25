local ui = require("engine.tech.ui")
local tk = require("engine.gui.tk")


local journal = {}

--- @class level.journal
local methods = {}
journal.mt = {__index = methods}

--- @return level.journal
journal.new = function()
  return setmetatable({
    
  }, journal.mt)
end

methods.draw = function(self, dt)
  tk.start_window("center", "center", "read_max", "max")
    ui.text("Hello there!")
  tk.finish_window()
end

Ldump.mark(journal, {mt = "const"}, ...)
return journal
