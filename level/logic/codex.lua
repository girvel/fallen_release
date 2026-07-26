local colors = require("engine.tech.colors")
local ui = require("engine.tech.ui")
local tk = require("engine.gui.tk")


local codex = {}

--- @class codex
--- @field page string
local methods = {}
codex.mt = {__index = methods}

local first_header

--- @return codex
codex.new = function()
  return setmetatable({
    page = "index",
  }, codex.mt)
end

--- @type table<string, fun(codex: codex)>
local pages = {}

methods.draw = function(self, dt)
  tk.start_window("center", "center", "read_max", 700)
    ui.h1("Журнал")
    first_header = true
    pages[self.page](self)
  tk.finish_window()
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
      ui.text("# ")

      if is_done then
        ui.finish_color()
        ui.text(text)
      else
        ui.text(text)
        ui.finish_color()
      end
    ui.finish_line()
  ui.finish_font()

  ui.offset(0, 20)
end

--- @param text string
--- @param is_done boolean
methods.li = function(self, text, is_done)
  ui.start_line()
    ui.start_color(colors.dark_red)

    if is_done then
      ui.text("+ ")
      ui.text(text)
      ui.finish_color()
    else
      ui.text("- ")
      ui.finish_color()
      ui.text(text)
    end
  ui.finish_line()
end

--- @param text string
--- @param destination string
methods.link = function(self, text, destination)
  if ui.text_button(text).is_clicked then
    self.page = destination
  end
end

pages.index = function(codex)
  local warmup = State.rails.quests.warmup
  if warmup > 0 then
    codex:header(warmup < 30 and "???" or "Разминка", warmup >= 1000)
    codex:li("Осмотреться", false)
    if State.rails.has_intro_note then
      ui.start_line()
        codex:li("Прочитать ")
        codex:link("записку", "intro_note")
      ui.finish_line()
    end
  end
end

pages.intro_note = function(codex)
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

Ldump.mark(codex, {mt = "const"}, ...)
return codex
