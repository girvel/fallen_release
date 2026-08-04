local stages = require("level.logic.stages")
local colors = require("engine.tech.colors")
local ui = require("engine.tech.ui")
local tk = require("engine.gui.tk")


----------------------------------------------------------------------------------------------------
-- [SECTION] Definition
----------------------------------------------------------------------------------------------------

local codex_module = {}

--- @class codex
--- @field history string[]
--- @field history_i integer
local methods = {}
codex_module.mt = {__index = methods}

local first_header

--- @return codex
codex_module.new = function()
  return setmetatable({
    page = "index",
    history = {"index"},
    history_i = 1,
  }, codex_module.mt)
end

--- @type table<string, fun(codex: codex)>
local pages = {}

local codex_scroll = {}

methods.draw = function(self, dt)
  tk.start_window("center", "center", "read_max", 700)
    ui.start_font(40)
      local w = ui.get_context().frame.w
      local offset = 100

      ui.start_frame(nil, nil, w / 2 - offset)
      ui.start_alignment("right")
        if self.history_i > 1 then
          if ui.text_button(" < ").is_clicked or ui.keyboard("left") then
            self:move(-1)
          end
        end
      ui.finish_alignment()
      ui.finish_frame()

      ui.start_frame(w / 2 + offset)
        if self.history_i < #self.history then
          if ui.text_button(" > ").is_clicked or ui.keyboard("right") then
            self:move(1)
          end
        end
      ui.finish_frame()

      ui.start_alignment("center")
        ui.text("Журнал")
      ui.finish_alignment()

      ui.br()
    ui.finish_font()

    first_header = true
    ui.start_frame(nil, nil, nil, nil, codex_scroll)
      pages[self.history[self.history_i]](self)
    ui.finish_frame()
  tk.finish_window()
end

----------------------------------------------------------------------------------------------------
-- [SECTION] Functionality
----------------------------------------------------------------------------------------------------

--- @param destination string
methods.go = function(self, destination)
  while #self.history > self.history_i do
    table.remove(self.history)
  end
  table.insert(self.history, destination)
  self.history_i = self.history_i + 1
end

--- @param offset -1|1
methods.move = function(self, offset)
  self.history_i = Math.median(1, self.history_i + offset, #self.history)
end

--- @param text string
--- @param value? integer
methods.header = function(self, text, value)
  value = value or 1

  ui.start_font(36)
    if first_header then
      first_header = false
    else
      ui.br()
    end

    ui.start_line()
      ui.start_color(colors.dark_red)

      if value >= stages.FAILED then
        ui.text("F ")
        ui.start_styles({text_strikethrough = true})
          ui.text(text)
        ui.finish_styles()
        ui.finish_color()
      elseif value >= stages.COMPLETED then
        ui.text("X "..text)
        ui.finish_color()
      else
        ui.text("# ")
        ui.finish_color()
        ui.text(text)
      end
    ui.finish_line()
  ui.finish_font()

  ui.offset(0, 20)
end

methods.start_li = function(self, is_done)
  ui.start_line()
  ui.start_color(colors.dark_red)

  if is_done then
    ui.text("+ ")
  else
    ui.text("- ")
    ui.finish_color()
  end
  ui.stack_push("codex_is_done", is_done)
end

methods.finish_li = function(self)
  local is_done = ui.stack_pop("codex_is_done")
  if is_done then
    ui.finish_color()
  end
  ui.finish_line()
end

--- @param text string
--- @param is_done boolean
methods.li = function(self, text, is_done)
  self:start_li(is_done)
    ui.text(text)
  self:finish_li()
end

--- @param text string
--- @param destination string
methods.link = function(self, text, destination)
  if ui.text_button(text).is_clicked then
    self:go(destination)
  end
end

----------------------------------------------------------------------------------------------------
-- [SECTION] Pages
----------------------------------------------------------------------------------------------------

pages.index = function(codex)
  local detective = State.rails.quests.detective
  if detective > 0 then
    codex:header(
      detective >= stages.detective._0020_investigate and "Рыцари и лжец" or "???",
      detective
    )

    codex:li("Найти комнату с чёрной дверью.", detective >= stages.detective._0020_investigate)

    if detective >= stages.detective._0020_investigate then
      codex:li(
        "Провести расследование в Машинном Отделении. Опросить свидетелей, осмотреть помещение. Затем устранить подозреваемого.",
        detective >= stages.detective._1000_completed
      )
    end
  end

  local warmup = State.rails.quests.warmup
  if warmup > 0 then
    codex:header(
      warmup < stages.warmup._0030_left and "???" or "Разминка",
      warmup
    )

    if warmup >= stages.warmup._0010_intro_heard then
      codex:li("Осмотреться", warmup >= stages.warmup._0020_needs_to_leave)
    end

    if State.rails.intro_note_status ~= "none" then
      codex:start_li(State.rails.intro_note_status == "read")
        ui.text("Прочитать ")
        codex:link("записку", "intro_note")
      codex:finish_li()
    end

    if warmup >= stages.warmup._0020_needs_to_leave then
      codex:li(
        "Выйти из помещения.",
        warmup >= stages.warmup._0030_left
      )
    end

    if warmup >= stages.warmup._0030_left then
      codex:li(
        "Пройти в тренировочную комнату; она должна находится вниз по коридору.",
        warmup >= stages.warmup._0040_in_room
      )
    end

    if State.rails.fighting_guide_status == "picked_up"
      or State.rails.fighting_guide_status == "read"
    then
      codex:start_li(State.rails.fighting_guide_status == "read")
        ui.text("Ознакомиться с ")
        codex:link("Как убить человека — 50 простых советов", "fighting_guide")
      codex:finish_li()
    end

    if warmup >= stages.warmup._0040_in_room then
      codex:li(
        "Выбрать себе оружие в тренировочной комнате.",
        warmup >= stages.warmup._0050_weapon_picked_up
      )
    end

    if warmup >= stages.warmup._0050_weapon_picked_up then
      codex:li(
        "Потренировать удары на чучеле. В комнате также должна быть методичка по основам битвы.",
        warmup >= stages.warmup._0060_practiced
      )
    end

    if warmup >= stages.warmup._0060_practiced then
      codex:li(
        "Активировать блок на столе и продолжить тренировку.",
        warmup >= stages.warmup._0070_mirage_defeated
      )
    end

    if warmup >= stages.warmup._0070_mirage_defeated then
      codex:li(
        "Покормить какую-то птицу в клетке. Корм должен быть в ящике.",
        warmup >= stages.warmup._1000_bird_fed
      )
    end
  end
end

local p = function(text)
  ui.text(text)
  ui.br()
end

pages.intro_note = function(codex)
  if State.rails.intro_note_status == "picked_up" then
    State.rails.intro_note_status = "read"
    State.rails:set_quest("warmup", stages.warmup._0020_needs_to_leave)
  end

  ui.h1("Записка коллеги")

  p("С пробуждением, брат.")
  p("Сейчас ты в смятении и это нормально. Моя смена начиналась в такой же растерянности, за этим я и составляю этот текст. читай внимательно, и все вопросы исчезнут.")
  p("Первое: выполняй задания, что приходят сверху.")
  p("Второе: следи за состоянием здоровья, соблюдай осторожность в работе.")
  p("Третие: не беспокой работающих без крайней нужды.")
  p("Четвёртое: очень важно, записывай в свой журнал указания сверху, очень просто забыть важное в работе.")
  p("Пятое и последнее: бывает, задания не сразу понятны. тут придется подумать, снова проверить журнал, что-то поискать или опросить других (смотри третий пункт).")
  p("Удачной работы, я от усталости уже вырубаюсь.")
end

pages.fighting_guide = function(codex)
  if State.rails.fighting_guide_status == "picked_up" then
    State.rails.fighting_guide_status = "read"
  end

  ui.h1("Как убить человека — 50 простых советов")

  p("*На обложке маленькой яркой книжки нарисована белка в тяжелом военном обмундировании; за бронированной спиной висят двуручной меч с секирой, в руках крупнокалиберный пулемёт; под ногами белки окровавленные шкуры волка, медведя и лисы с крестиками на глазах*")

  p("Мой дорогой друг! Если ты читаешь эту книгу, значит ты хочешь научиться убивать! Убивать очень просто, следуй советам храброй белки и ты будешь живее своих врагов!")

  p("Рекомендованная цена: 12 Мари-Ланн")

  p("Совет 3: Не отворачивайся от врага, мой юный друг, если не хочешь получить по шее! Однажды, мой знакомый ёжик испугался ножа в руках братца-кролика, повернулся и побежал; не будь у него иголок — получил бы ножом на отходе!")

  p("Совет 8: Смотрел кинофильм “Болот — Великий воин”? Где он в каждую руку топор и давай врагов кромсать! Так вот — бывает это только на экране, с двумя тяжестями тебе не управиться. Но вот чем-то лёгким — запросто, обязательно попробуй, так можно бить в 2 раза чаще! ")

  p("Совет 15: Даже в успешном бою нет-нет — да заденут, никогда не забывай о перевязках! Смелый бельчонок потому и живой, что после каждого боя раны зализывает!")

  p("Совет 37: Лучшее лекарство — хороший сон и обед; не слушай байки про дефицит лекарств и демпингующих жрецов — лечись отдыхая!")
end

Ldump.mark(codex_module, {mt = "const"}, ...)
return codex_module
