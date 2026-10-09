local console = {}

console.run = function()
  Stack = {}
  for level = 1, math.huge do
    if not debug.getinfo(level) then break end
    local locals = {}
    for local_i = 1, math.huge do
      local k, v = debug.getlocal(level, local_i)
      if not k then break end
      locals[k] = v
    end
    Stack[level] = locals
  end

  while true do
    io.write("lua> ")
    local f, err = loadstring("return "..io.read())
    if err then
      f, err = loadstring(io.read())
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