local rails = {}

--- @class rails
local methods = {}
rails.mt = {__index = methods}

--- @param checkpoint string?
--- @return rails
rails.new = function(checkpoint)
  assert(checkpoint == nil, "No checkpoints available")
  return setmetatable({}, rails.mt)
end

Ldump.mark(rails, {mt = "const"}, ...)
return rails
