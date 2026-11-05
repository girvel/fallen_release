local composite_map = {}

--- @class composite_map
--- @field _items table<any, composite_map>
--- @field _value any
--- @field _weakness? "weak"
local methods = {}
composite_map.mt = {__index = methods}
composite_map._weak_items_mt = {__mode = "k"}

--- @param weakness? "weak"
--- @return composite_map
composite_map.new = function(weakness)
  local items = {}
  if weakness == "weak" then
    setmetatable(items, composite_map._weak_items_mt)
  end
  return setmetatable({_items = items, _weakness = weakness}, composite_map.mt)
end

--- @param value any
--- @param head any
--- @param ... any
methods.set = function(self, value, head, ...)
  if head == nil then
    self._value = value
    return
  end

  if not self._items[head] then
    self._items[head] = composite_map.new(self._weakness)
  end

  self = self._items[head]
  methods.set(self, value, ...)
end


--- @param head any
--- @param ... any
--- @return any
methods.get = function(self, head, ...)
  if head == nil then
    return self._value
  end

  if not self._items[head] then
    return nil
  end

  self = self._items[head]
  return methods.get(self, ...)
end

local iter
iter = function(self, base)
  if self._value then
    coroutine.yield(base, self._value)
  end
  for k, v in pairs(self._items) do
    table.insert(base, k)
    iter(v, base)
    table.remove(base)
  end
end

--- NOTICE returned keys should not be mutated
methods.iter = function(self)
  return coroutine.wrap(function() iter(self, {}) end)
end

local is_callable
is_callable = function(f)
  local tf = type(f)
  if tf == "function" then return true end
  if tf == "table" then
    local mt = getmetatable(f)
    return type(mt) == "table" and is_callable(mt.__call)
  end
  return false
end

composite_map.memoize = function(f, cache)
  local map = composite_map.new()
  if cache then
    map._items = cache
  end

  if not is_callable(f) then
    error(string.format(
      "Only functions and callable tables are memoizable. Received %s (a %s)",
      tostring(f), type(f)
    ))
  end

  return function(...)
    local results = map:get(...)
    if not results then
      results = {f(...)}
      map:set(results, ...)
    end
    return unpack(results)
  end
end

return composite_map
