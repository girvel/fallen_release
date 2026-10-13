local console = {}

local POS_KEY = "(pos)"

--- @param thread thread?
--- @return table<string, any>[]
console.capture_stack = function(thread)
  local result = {}
  for level = 0, math.huge do
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
    print(CoStack[0])
    for _, locals in ipairs(CoStack) do
      print(locals[POS_KEY])
    end
    print("Stack:")
  end
  print(Stack[0])
  for _, locals in ipairs(Stack) do
    print(locals[POS_KEY])
  end
end

--- @param msg string?
console.run = function(msg)
  Stack = console.capture_stack()
  if msg then print(msg) end
  print_trace()

  while true do
    io.write("lua> ")
    local input = io.read()
    if not input then break end
    local cmd = input:lower()
    if cmd == ":trace" or cmd == ":t" then
      print_trace()
      goto continue
    elseif cmd == ":continue" or cmd == ":c" then
      break
    elseif cmd == "help" or cmd == "h" or cmd == ":help" or cmd == ":h" then
      print("Shell accepts lua expressions & statements")
      print()
      print("  COMMANDS:")
      print(":trace    -- display the trace of the stack")
      print(":continue -- proceed with the execution")
      print()
      print("  GLOBALS:")
      print("Last    -- contains the value of the last expression")
      print("Stack   -- contains a copy of the stack")
      print("CoStack -- global contains a copy of the coroutine stack")
      goto continue
    end

    local is_expr = true
    local f, err = loadstring("Last = "..input)
    if not f then
      f, err = loadstring(input)
      if not f then
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
      --- @diagnostic disable-next-line:undefined-global
      print(Inspect(Last, {depth = 1, keys_limit = 20}))
    end

    ::continue::
  end
end

Ldump.mark(console, {}, ...)
return console
