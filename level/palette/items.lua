--- @class palette.items: mech.weapons
local items = {}
Table.extend(items, require("engine.mech.weapons"))

Ldump.mark(items, {}, ...)
return items
