local stages = require("level.logic.stages")
local colors = require("engine.tech.colors")
local ui = require("engine.tech.ui")
local tk = require("engine.gui.tk")


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

methods.draw = function(self, dt)
  tk.start_window("center", "center", "read_max", 700)
    ui.start_font(40)
      local w = ui.get_context().frame.w
      local offset = 100

      ui.start_frame(nil, nil, w / 2 - offset)
      ui.start_alignment("right")
        if self.history_i > 1 then
          if ui.text_button(" < ").is_clicked then self:move(-1) end
        end
      ui.finish_alignment()
      ui.finish_frame()

      ui.start_frame(w / 2 + offset)
        if self.history_i < #self.history then
          if ui.text_button(" > ").is_clicked then self:move(1) end
        end
      ui.finish_frame()

      ui.start_alignment("center")
        ui.text("Журнал")
      ui.finish_alignment()

      ui.br()
    ui.finish_font()

    first_header = true
    pages[self.history[self.history_i]](self)
  tk.finish_window()
end

--- @param destination string
methods.go = function(self, destination)
  table.insert(self.history, destination)
  self.history_i = self.history_i + 1
end

--- @param offset -1|1
methods.move = function(self, offset)
  self.history_i = Math.median(1, self.history_i + offset, #self.history)
end

--- @param text string
--- @param is_done boolean
methods.header = function(self, text, is_done)
  ui.start_font(36)
    if first_header then
      first_header = false
    else
      ui.br()
    end

    ui.start_line()
      ui.start_color(colors.dark_red)

      if is_done then
        ui.text("X ")
        ui.text(text)
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

pages.index = function(codex)
  local warmup = State.rails.quests.warmup
  if warmup > 0 then
    codex:header(
      warmup < stages.warmup.left and "???" or "Разминка",
      warmup >= stages.COMPLETED
    )

    if warmup >= stages.warmup.intro_heard then
      codex:li("Осмотреться", warmup >= stages.warmup.needs_to_leave)
    end

    if State.rails.intro_note_status ~= "none" then
      codex:start_li(State.rails.intro_note_status == "read")
        ui.text("Прочитать ")
        codex:link("записку", "intro_note")
      codex:finish_li()
    end

    if warmup >= stages.warmup.needs_to_leave then
      codex:li(
        "Выйти из помещения.",
        warmup >= stages.warmup.left
      )
    end

    if warmup >= stages.warmup.left then
      codex:li(
        "Пройти в тренировочную комнату; она должна находится вниз по коридору.",
        warmup >= stages.warmup.in_room
      )
    end

    if warmup >= stages.warmup.in_room then
      codex:li(
        "Выбрать себе оружие в тренировочной комнате.",
        warmup >= stages.warmup.weapon_picked_up
      )
    end

    if warmup >= stages.warmup.weapon_picked_up then
      codex:li(
        "Потренировать удары на чучеле. В комнате также должна быть методичка по основам битвы.",
        warmup >= stages.warmup.practiced
      )
    end

    if warmup >= stages.warmup.practiced then
      codex:li(
        "Активировать блок на столе и продолжить тренировку.",
        warmup >= stages.warmup.mirage_defeated
      )
    end

    if warmup >= stages.warmup.bird_fed then
      codex:li(
        "Покормить какую-то птицу в клетке. Корм должен быть в ящике.",
        warmup >= stages.warmup.bird_fed
      )
    end
  end
end

pages.intro_note = function(codex)
  if State.rails.intro_note_status == "picked_up" then
    State.rails.intro_note_status = "read"
    State.rails:set_quest("warmup", stages.warmup.needs_to_leave)
  end

  ui.h1("Записка коллеги")

  ui.text("С пробуждением, брат."); ui.br()
  ui.text("Сейчас ты в смятении и это нормально. Моя смена начиналась в такой же растерянности, за этим я и составляю этот текст. читай внимательно, и все вопросы исчезнут."); ui.br()
  ui.text("Первое: выполняй задания, что приходят сверху."); ui.br()
  ui.text("Второе: следи за состоянием здоровья, соблюдай осторожность в работе."); ui.br()
  ui.text("Третие: не беспокой работающих без крайней нужды."); ui.br()
  ui.text("Четвёртое: очень важно, записывай в свой журнал указания сверху, очень просто забыть важное в работе."); ui.br()
  ui.text("Пятое и последнее: бывает, задания не сразу понятны. тут придется подумать, снова проверить журнал, что-то поискать или опросить других (смотри третий пункт)."); ui.br()
  ui.text("Удачной работы, я от усталости уже вырубаюсь.")
end

Ldump.mark(codex_module, {mt = "const"}, ...)
return codex_module
