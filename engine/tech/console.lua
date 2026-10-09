local console = {}

local POS_KEY = "(pos)"

--- @param thread thread?
--- @return table<string, any>[]
console.capture_stack = function(thread)
  local result = {}
  for level = 1, math.huge do
    local info
    if thread then
      info = debug.getinfo(thread, level)
    else
      info = debug.getinfo(level)
    end
    if not info then break end
    
    local repr = level..". "..info.short_src..":"..info.currentline
    if info.name then
      repr = repr.." in "..info.namewhat.." '"..info.name.."'"
    end
    local locals = {
      [POS_KEY] = repr,
    }
    
    for local_i = 1, math.huge do
      local k, v
      if thread then
        k, v = debug.getlocal(thread, level, local_i)
      else
        k, v = debug.getlocal(level, local_i)
      end
      if not k then break end
      
      locals[k] = v
    end
    result[level] = locals
  end
  return result
end

local print_trace = function()
  if CoStack then
    print("CoStack:")
    for i, locals in ipairs(CoStack) do
      print(locals[POS_KEY])
    end
    print("Stack:")
  end
  for i, locals in ipairs(Stack) do
    print(locals[POS_KEY])
  end
end

console.run = function()
  Stack = console.capture_stack()
  print_trace()

  while true do
    io.write("lua> ")
    local input = io.read()
    local cmd = input:lower()
    if cmd == ":trace" then
      print_trace()
      goto continue
    elseif cmd == "help" or cmd == "h" or cmd == ":help" or cmd == ":h" then
      print("Use :trace to display the trace of the stack")
      print("Last global contains the value of the last expression")
      print("Stack global contains a copy of the stack")
      print("CoStack global contains a copy of the coroutine stack")
      print("Shell accepts lua expressions & statements")
      goto continue
    end
    
    local is_expr = true
    local f, err = loadstring("Last = "..input)
    if err then
      f, err = loadstring(input)
      if err then
        print(err)
        goto continue
      end
      is_expr = false
    end
    
    local ok, result = pcall(f)
    if not ok then
      print(result)
      goto continue
    end
    
    if is_expr then
      print(Inspect(Last, {depth = 1, keys_limit = 20}))
    end
    
    ::continue::
  end
end

Ldump.mark(console, {}, ...)
return console