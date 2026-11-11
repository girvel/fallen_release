local hot_reload = require("engine.tech.hot_reload")
local spells = require("engine.mech.spells")
local class = require("engine.mech.class")
local ui = require("engine.tech.ui")
local gui_elements = require("engine.gui.gui_elements")
local warlock_class = require("engine.mech.class.warlock")


local warlock = {}

--- @param data creator_pane
warlock.init_data = function(data)

end

--- @param creator gui_creator
--- @param dt number
--- @param data creator_pane
warlock.draw_pane = function(creator, dt, data)
  if data.class_level == 1 then
    creator:start_ability(gui_elements.eldritch_blast)
      ui.text("Заговор: Мистический взрыв")
    creator:finish_ability("Дистанционная атака, 1d10 урона")

    creator:start_ability(gui_elements.warlock_slots_1)
      ui.text("Ячейки колдовства: 1x1")
    creator:finish_ability("1 заклинание уровня 1 за бой")

    creator:start_ability(gui_elements.hex_1)
      ui.text("Заклинание: Сглаз")
    creator:finish_ability("+1d6 урона по проклятому противнику")

    creator:start_ability(gui_elements.dark_ones_blessing)
      ui.text("Способность: Благословение Тёмного")
    creator:finish_ability("Временное здоровье при убийстве")
  elseif data.class_level == 2 then
    creator:start_ability(gui_elements.eldritch_blast_perk)
      ui.text("Способность: Мучительный взрыв")
    creator:finish_ability("%+d (ХАР) урона к Мистическому взрыву", creator:get_modifier("cha"))

    creator:start_ability(gui_elements.eldritch_blast_perk)
      ui.text("Способность: Отталкивающий взрыв")
    creator:finish_ability("Мистический Взрыв толкает противников назад")

    creator:start_ability(gui_elements.warlock_slots_2)
      ui.text("Ячейки колдовства: 2x1")
    creator:finish_ability("2 заклинания уровня 1 за бой")
  elseif data.class_level == 3 then
    creator:start_ability(gui_elements.warlock_slots_2)
      ui.text("Ячейки колдовства: 2x2")
    creator:finish_ability("2 заклинания уровня 2 за бой")

    creator:start_ability(gui_elements.hold_person_2)
      ui.text("Заклинание: Удержание личности")
    creator:finish_ability("Попытаться парализовать противника")
  elseif data.class_level == 4 then
    creator:start_ability(gui_elements.spray_of_cards_2)
      ui.text("Заклинание: Веер карт")
    creator:finish_ability("2d10 урона по конусу + ослепление")
  end
end

--- @param creator gui_creator
--- @param datas creator_pane[]
--- @param perks table[]
warlock.submit = function(creator, datas, perks)
  for _, data in ipairs(datas) do
    if data.class_level == 1 then
      table.insert(perks, class.spell(spells.eldritch_blast, "cha"))
      table.insert(perks, class.spell(spells.hex, "cha"))
    elseif data.class_level == 2 then
      table.insert(perks, warlock_class.agonizing_blast)
      table.insert(perks, warlock_class.repelling_blast)
    elseif data.class_level == 3 then
      table.insert(perks, class.spell(spells.hold_person, "cha"))
    elseif data.class_level == 4 then
      table.insert(perks, class.spell(spells.spray_of_cards, "cha"))
    end
  end
  local class_level = #datas
  table.insert(perks, warlock_class.spell_slots(class_level))
  table.insert(perks, warlock_class.dark_ones_blessing(class_level))
end

hot_reload.mark(warlock, ...)
Ldump.mark(warlock, {}, ...)
return warlock
