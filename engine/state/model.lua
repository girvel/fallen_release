local model = {}

--- @alias dialogue_line dialogue_line.plain | dialogue_line.options

--- @class dialogue_line.plain
--- @field type "plain_line"
--- @field source entity?
--- @field text string

--- @class dialogue_line.options
--- @field type "options"
--- @field options table<integer, string>

--- @class popup
--- @field draw fun()
--- @field position vector
--- @field life_time number

--- @class state.model
--- @field hears? dialogue_line
--- @field speaks? integer
--- @field notification? string
--- @field order? string
--- @field suggestion? string
--- @field popups popup[]
--- @field curtain_color vector
--- @field curtain_draw fun()?
--- @field memory love.Canvas
--- @field is_memory_enabled boolean
--- @field is_blind boolean
--- @field is_deaf boolean
--- @field journal_new fun(): table
--- @field has_new_task boolean
local methods = {}
model.mt = {__index = methods}

--- @return state.model
model.new = function()
  return setmetatable({
    curtain_color = Vector.transparent,
    is_memory_enabled = true,
    is_blind = false,
    is_deaf = false,
    has_new_task = false,
    popups = {},
  }, model.mt)
end

Ldump.mark(model, {mt = "const"}, ...)
return model
