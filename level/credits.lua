local ui = require("engine.tech.ui")


local credits = {}

local gap_before_title
local GAP_AFTER_TITLE = 35
local SPEED = 20
local SCROLL_SPEED = 200
local CREDIT_GAP = 20
local BLOCK_GAP = 120
local offset = 0

--- @param text string
local header = function(text)
  ui.start_font(40)
  ui.start_alignment("center")
    ui.text(text)
    ui.offset(0, 25)
  ui.finish_alignment()
  ui.finish_font()
end

--- @param t [string, string][]
local block = function(t)
  local halfw = love.graphics.getWidth() / 2
  ui.start_font(24)
    ui.start_frame(0, 0, halfw - CREDIT_GAP / 2)
    ui.start_alignment("right")
      for _, pair in ipairs(t) do
        local left, _ = unpack(pair)
        ui.text(left)
      end
    ui.finish_alignment()
    ui.finish_frame()

    ui.start_frame(halfw + CREDIT_GAP / 2, 0, halfw - CREDIT_GAP / 2)
      for _, pair in ipairs(t) do
        local _, right = unpack(pair)
        ui.text(right)
      end
    ui.finish_frame("push_cursor")
  ui.finish_font()
  ui.offset(0, BLOCK_GAP)
end

--- @param items string[]
local list = function(items)
  ui.start_font(24)
  ui.start_alignment("center")
    for _, item in ipairs(items) do
      ui.text(item)
    end
  ui.finish_alignment()
  ui.finish_font()
  ui.offset(0, BLOCK_GAP)
end

credits.draw_gui = function(self, dt)
  if love.keyboard.isDown("space") then
    offset = offset + dt * SCROLL_SPEED
  else
    offset = offset + dt * SPEED
  end
  gap_before_title = gap_before_title or love.graphics.getHeight() - 100

  ui.start_frame(0, gap_before_title - offset)
    ui.start_alignment("center")
    ui.start_font(200)
      ui.text("FALLEN")
    ui.finish_font()
    ui.finish_alignment()
    ui.offset(0, GAP_AFTER_TITLE)

    header("Команда разработки")

    block {
      {"Автор", "Сергей Хабаров"},
      {"Редактор", "Никита Добрынин"},
      {"Разработчик", "Никита Добрынин"},
      {"Левел-дизайнер", "Никита Добрынин"},
      {"Саунд-дизайнер", "Никита Добрынин"},
      {"Художник", "Никита Добрынин"},
      {"Художник-иллюстратор", "Маша"},
      {"Аниматор", "Никита Добрынин"},
      {"Сценарист", "Дмитрий Сироткин"},
    }

    header("Тестировщики")

    list {
      "Дмитрий Сироткин",
      "Александр Потехин",
      "Артём Алямовский",
      "",
      "и многие другие...",
    }

    header("Открытые ресурсы")

    block {
      {"Фреймворк", "LOVE2D"},
      {"CLI библиотека", "argparse by Peter Melnichenko"},
      {"Функциональная библиотека", "luafun by Roman Tsysyk"},
      {"Библиотека мемоизации", "memoize by Enrique García Cota"},
      {"Библиотека визуализации объектов", "inspect.lua by Enrique García Cota"},
      {"Библиотека для логов", "log.lua by rxi"},
      {"JSON библиотека", "json.lua by rxi"},
      {"ECS библиотека", "tiny.lua by Calvin Rose"},
      {"Поиск пути и углы обзора", "libtcod by Jice and contributors"},
      {"Профайлер", "profile.lua by 2dengine LLC"},
      {"Редактор уровней", "LDtk by Sébastien Benard"},
      {"Звуковые эффекты", "GameAudioGDC"},
      {"Палитра", "Comfort44s by AndréM. | Palm"},
      {"Стилистическое вдохновение", "Abyss by Lj V. Miranda"},
      {"Вода", "TutsByKai"},
      {"Шрифт", "Classic Console Neue by deejayy.hu"},
      {"Референс для декораций", "1-Bit Pack by Kenney.nl"},
      {"Спрайт гуманоида", "B&W Surreal Office by SdiviHall"},
      {"", ""},
      {"", "и многие другие..."},
    }

    if ui.get_context().cursor_y < 0 then
      Kernel.gui:to_start_screen()
    end
  ui.finish_frame()
end

return credits
