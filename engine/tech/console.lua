local console = {}

local POS_KEY = "(pos)"

console.run = function()
  Stack = {}
  for level = 1, math.huge do
    local info = debug.getinfo(level)
    if not info then break end
    local repr = level..". "..info.short_src..":"..info.currentline
    if info.name then
      repr = repr.." in "..info.namewhat.." '"..info.name.."'"
    end
    local locals = {
      [POS_KEY] = repr,
    }
    
    for local_i = 1, math.huge do
      local k, v = debug.getlocal(level, local_i)
      if not k then break end
      locals[k] = v
    end
    Stack[level] = locals
  end

  while true do
    io.write("lua> ")
    local input = io.read()
    local cmd = input:lower()
    if cmd == ":trace" then
      for i, locals in ipairs(Stack) do
        print(locals[POS_KEY])
      end
      goto continue
    elseif cmd == "help" or cmd == "h" or cmd == ":help" or cmd == ":h" then
      print("Use :trace to display the trace of the stack")
      print("Stack global contains the copy of the stack itself")
      print("Shell accepts lua expressions & statements")
      goto continue
    end
    
    local f, err = loadstring("return "..input)
    if err then
      f, err = loadstring(input)
      if err then
        print(err)
        goto continue
      end
    end
    
    local ok, result = pcall(f)
    if not ok then
      print(result)
      goto continue
    end
    
    print(Inspect(result, {depth = 1, keys_limit = 20}))
    
    ::continue::
  end
end

Ldump.mark(console, {}, ...)
return console