local ui = require("engine.tech.ui")
local tcod = require("engine.tech.tcod")


local start_menu = {}

--- @class gui_start_menu
--- @field type "start_menu"
local methods = {}
local mt = {__index = methods}

start_menu.new = function()
  return setmetatable({
    type = "start_menu",
  }, mt)
end

local display_tcod_error = not tcod.ok

local choices
local checkpoints

methods.draw_gui = function()
  Kernel:ambient_start()
  if display_tcod_error then
    display_tcod_error = false
    Kernel.gui:show_warning(
      "Невозможно загрузить библиотеку libtcod, поля зрения и поиск путей не будут работать." ..
      "\n\nВозможно, путь к папке с игрой содержит русские символы. Попробуйте " ..
      "переместить её в другое место."
    )
    return
  end

  if not choices then
    choices = {
      "Новая игра",
      "Загрузить игру",
    }
    if Kernel.config.internal_build then
      local rails = require("level.rails")
      checkpoints = {}
      for cp_name in pairs(rails.checkpoints) do
        table.insert(checkpoints, cp_name)
      end
      table.sort(checkpoints)
      for _, cp_name in ipairs(checkpoints) do
        table.insert(choices, 'Чекпоинт "'..cp_name..'"')
      end
    end
    table.insert(choices, "Выход")
  end

  ui.start_frame(0, 100)
  ui.start_font(72)
  ui.start_alignment("center")
    ui.text("Fallen")
  ui.finish_alignment()
  ui.finish_font()
  ui.finish_frame()

  ui.start_font(48)
  ui.start_frame(100, 300, 500, 500)
    local choice = ui.choice(choices)
    if choice then
      ui.reset_selection()
    end

    if choice == 1 then
      Kernel.gui:load_level()
    elseif choice == 2 then
      Kernel.gui:open_menu("load_menu")
    elseif choice == #choices then
      Log.info("Exiting from the main menu")
      love.event.quit()
    elseif choice then
      local checkpoint = checkpoints[choice - 2]
      Log.info("Setting checkpoint to %s", checkpoint)
      Kernel.args.checkpoint = checkpoint
      Kernel.gui:load_level()
    end
  ui.finish_frame()
  ui.finish_font()
end

Ldump.mark(start_menu, {}, ...)
return start_menu
