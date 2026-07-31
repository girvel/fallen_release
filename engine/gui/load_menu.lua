local saves = require("engine.kernel.saves")
local loading_screen = require("engine.gui.loading_screen")
local tk = require("engine.gui.tk")
local ui = require("engine.tech.ui")


local load_menu = {}

--- @class gui_load_menu
--- @field type "load_menu"
--- @field _prev table
local methods = {}
local mt = {__index = methods}

--- @param prev table
--- @return gui_load_menu
load_menu.new = function(prev)
  return setmetatable({
    type = "load_menu",
    _prev = prev,
  }, mt)
end

tk.delegate(methods, "draw_entity", "preprocess", "postprocess")

methods.draw_gui = function(self, dt)
  tk.start_window("center", "center", "read_max", "max")
  ui.start_font(24)
    ui.h1("Загрузить игру")

    local save = tk.choose_save(false)
    local escape_pressed = ui.keyboard("escape")

    if save then
      local load_f = function()
        State = saves.read("saves/"..save..".ldump.gz")  --[[@as state]]
        State.runner:handle_loading()
      end

      -- NEXT remove this argument
      -- NEXT gui method
      local final_f = function()
        Kernel.gui:start_game()
      end

      Kernel.gui:_set_mode(loading_screen.new(coroutine.create(load_f), final_f))
    else if escape_pressed then
      ui.reset_selection()
      Kernel.gui:close_menu()
    end
  end
  ui.finish_font()
  tk.finish_window()
end

Ldump.mark(load_menu, {}, ...)
return load_menu
