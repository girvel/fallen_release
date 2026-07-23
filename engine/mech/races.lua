local races = {}

races.human = {
  codename = "human",
  name = "Разносторонний человек",
  skin_color = Vector.hex("8ed3dc"),

  perk = {
    codename = "ability_bonus_human",
    modify_ability_score = function(self, entity, score, ability)
      return score + 1
    end,
  }
}

races.variant_human = {
  codename = "variant_human",
  name = "Альтернативный человек",
  skin_color = Vector.hex("8ed3dc"),

  perk = Memoize(function(_, ability1, ability2)
    return {
      codename = "ability_bonus_variant_human",
      modify_ability_score = function(self, entity, score, ability)
        if ability == ability1 or ability == ability2 then
          return score + 1
        end
        return score
      end
    }
  end),
}

races.custom_lineage = {
  codename = "custom_lineage",
  name = "Необычное происхождение",
  skin_color = Vector.hex("8ed3dc"),

  perk = Memoize(function(_, ability1)
    return {
      codename = "ability_bonus_custom_lineage",
      modify_ability_score = function(self, entity, score, ability)
        if ability == ability1 then
          return score + 1
        end
        return score
      end
    }
  end),
}

races.half_orc = {
  codename = "half_orc",
  skin_color = Vector.hex("60b37e"),
}

races.half_elf = {
  codename = "half_elf",
  skin_color = Vector.hex("c9c7ec"),
}

races.halfling = {
  codename = "halfling",
  skin_color = Vector.hex("d2d2ba"),
}

races.dwarf = {
  codename = "dwarf",
  skin_color = Vector.hex("8ed3dc"),
}

Ldump.mark(races, "const", ...)
return races
