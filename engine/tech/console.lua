local console = {}

console.run = function()
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