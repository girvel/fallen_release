--- Module with uncategorized utility functions
local common = {}

--- @generic T
--- @param value T
--- @return T
common.nil_serialized = function(value)
  Ldump.serializer.handlers[value] = "nil"
  return value
end

--- @param expression string
--- @return any
common.eval = function(expression)
  local f = loadstring("return " .. expression, expression)
  if not f then
    error(("Invalid syntax in %q"):format(expression), 1)
  end
  return f()
end

--- @return integer?
--- @return any
local getupvaluen = function(f, name)
  for i = 1, math.huge do
    local k, v = debug.getupvalue(f, i)
    if not k then return end
    if k == name then return i, v end
  end
end

--- @param f function
common.locals = function(f)
  return setmetatable({}, {
    __index = function(self, key)
      local _, v = getupvaluen(f, key)
      return v
    end,

    __newindex = function(self, key, value)
      local i = getupvaluen(f, key)
      if not i then error("No upvalue "..key) end
      debug.setupvalue(f, i, value)
    end,
  })
end

return common
