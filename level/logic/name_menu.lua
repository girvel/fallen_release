local ui = require("engine.tech.ui")
local tk = require("engine.gui.tk")
local name_menu = {}

--- @class name_menu
--- @field name string
local methods = {}
name_menu.mt = {__index = methods}

--- @return name_menu
name_menu.new = function(prev)
  return setmetatable({
    type = "name_menu",
    _prev = prev,
    name = State.player.name or "Протагонист",
  }, name_menu.mt)
end

tk.delegate(methods, "draw_entity", "preprocess", "postprocess")

local W = 500
local H = 150
local PADDING = 20

methods.draw_gui = function(self, dt)
  Log.traces(1)
  tk.start_window(love.graphics.getWidth() - W - PADDING, "center", W, H)
  ui.start_font(24)
    ui.start_line()
      ui.selector()
      ui.text("Имя:  ")
      ui.field(self, "name", 22)
    ui.finish_line()
    ui.start_alignment("center", "bottom")
    ui.start_font(36)
      local ok_button = ui.choice({"ОК"})
    ui.finish_font()
    ui.finish_alignment()
  ui.finish_font()
  tk.finish_window()

  if ok_button or ui.keyboard("return") then
    Log.info("Submitted the name %q", State.player.name)
    State.player.name = self.name:strip()
    Kernel.gui:close_menu()
  end

  if ui.keyboard("escape") then
    Kernel.gui:open_menu("escape_menu")
  end
end

Ldump.mark(name_menu, {mt = "const"}, ...)
return name_menu
