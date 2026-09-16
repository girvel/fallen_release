local sprite = require("engine.tech.sprite")


local icon_atlas

local nth = function(index)
  return love.graphics.newImageRaw(sprite.utility.select(icon_atlas, index))
end

local gui_elements = {}

gui_elements.assign = function()
  icon_atlas = love.image.newImageData("engine/assets/gui/icons.png")

  gui_elements.skip_turn = nth(1)
  gui_elements.dash = nth(2)
  gui_elements.interact = nth(3)
  gui_elements.disengage = nth(4)
  gui_elements.hit_dice = nth(5)
  gui_elements.hand_attack = nth(6)
  gui_elements.offhand_attack = nth(7)
  gui_elements.shove = nth(8)

  gui_elements.skip_turn_inactive = nth(9)
  gui_elements.dash_inactive = nth(10)
  gui_elements.interact_inactive = nth(11)
  gui_elements.disengage_inactive = nth(12)
  gui_elements.hit_dice_inactive = nth(13)
  gui_elements.hand_attack_inactive = nth(14)
  gui_elements.offhand_attack_inactive = nth(15)
  gui_elements.shove_inactive = nth(16)

  gui_elements.journal = nth(17)
  gui_elements.escape_menu = nth(18)
  gui_elements.creator = nth(19)
  gui_elements.journal_inactive = nth(25)
  gui_elements.creator_inactive = nth(27)

  gui_elements.escape = nth(21)
  gui_elements.escape_inactive = nth(29)

  gui_elements.bow_attack = nth(22)
  gui_elements.unknown = nth(23)
  gui_elements.bow_attack_inactive = nth(30)
  gui_elements.unknown_inactive = nth(31)

  gui_elements.second_wind = nth(33)
  gui_elements.action_surge = nth(34)
  gui_elements.fighting_spirit = nth(35)
  gui_elements.great_weapon_master = nth(36)

  gui_elements.second_wind_inactive = nth(41)
  gui_elements.action_surge_inactive = nth(42)
  gui_elements.fighting_spirit_inactive = nth(43)
  gui_elements.great_weapon_master_inactive = nth(44)

  gui_elements.fighting_styles = nth(49)
  gui_elements.generic_perk = nth(50)
  gui_elements.dark_ones_blessing = nth(51)
  gui_elements.eldritch_blast_perk = nth(52)
  gui_elements.fighter = nth(53)
  gui_elements.warlock = nth(54)
  gui_elements.eldritch_blast = nth(65)
  gui_elements.animate_dead_3 = nth(66)
  gui_elements.healing_word_1 = nth(67)
  gui_elements.healing_word_2 = nth(68)
  gui_elements.healing_word_3 = nth(69)
  gui_elements.spray_of_cards_2 = nth(70)
  gui_elements.spray_of_cards_3 = nth(71)
  gui_elements.hold_person_2 = nth(72)
  gui_elements.hold_person_3 = nth(72)
  gui_elements.eldritch_blast_inactive = nth(73)
  gui_elements.animate_dead_3_inactive = nth(74)
  gui_elements.healing_word_1_inactive = nth(75)
  gui_elements.healing_word_2_inactive = nth(76)
  gui_elements.healing_word_3_inactive = nth(77)
  gui_elements.spray_of_cards_2_inactive = nth(78)
  gui_elements.spray_of_cards_3_inactive = nth(79)
  gui_elements.hold_person_2_inactive = nth(80)
  gui_elements.hold_person_3_inactive = nth(80)

  gui_elements.window_bg = "engine/assets/gui/window_bg.png"
  gui_elements.bar_bg = "engine/assets/gui/bar_bg.png"
  gui_elements.hp_bar = "engine/assets/gui/hp_bar.png"
  gui_elements.hp_bar_min = "engine/assets/gui/hp_bar_min.png"
  gui_elements.hp_bar_extra = "engine/assets/gui/hp_bar_extra.png"
  gui_elements.xp_bar = "engine/assets/gui/xp_bar.png"
  gui_elements.xp_bar_min = "engine/assets/gui/xp_bar_min.png"
  gui_elements.sidebar_block_bg = "engine/assets/gui/sidebar_block_bg.png"
end

gui_elements.assign()


Ldump.mark(gui_elements, {}, ...)
return gui_elements
