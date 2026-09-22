local async = require("engine.tech.async")


local sometimes = async.sometimes()
local sometimes_deser = async.sometimes(1)
local counter = 0

local old_serialize = getmetatable(Ldump.serializer).__call
Ldump.serializer = setmetatable({
  handlers = Ldump.serializer.handlers,
}, {
  __call = function(self, x)
    local a, b = old_serialize(self, x)
    sometimes:yield()
    if a then
      if type(a) == "function" then
        counter = counter + 1
        if counter % 50 == 0 then
          return function()
            sometimes_deser:yield()
            return a()
          end
        end
      end
      return a, b
    end

    if type(x) == "userdata"
      and pcall(function() return x.typeOf end)
      and x:typeOf("ImageData")
    then
      --- @cast x love.ImageData
      local repr = x:encode("png"):getString()
      return function()
        return love.image.newImageData(
          love.filesystem.newFileData(repr, "tmp.png")
        )
      end
    end
  end,
})

local wrap = function(modname, fname, memoize)
  local old = love[modname][fname]
  love[modname][fname] = function(...)
    local result = old(...)
    local args = {...}
    Ldump.serializer.handlers[result] = function()
      return love[modname][fname](unpack(args))
    end
    return result
  end

  if memoize then
    local cache = {}
    love[modname][fname] = Memoize(love[modname][fname], cache)
    love[modname][fname.."Cache"] = cache
  end
end

love.graphics.newCanvasRaw = love.graphics.newCanvas
love.graphics.newImageRaw = love.graphics.newImage

do
  local cache = {}

  --- @diagnostic disable-next-line:duplicate-set-field
  love.graphics.newImage = function(arg1, ...)
    assert(select("#", ...) == 0)

    if type(arg1) ~= "string" then
      assert(arg1:typeOf("ImageData"))
      local result = love.graphics.newImageRaw(arg1, ...)
      local repr = arg1:encode("png"):getString()
      Ldump.serializer.handlers[result] = function()
        -- NEXT repetition of saving would break this
        return love.graphics.newImage(
          love.filesystem.newFileData(repr, "tmp.png")
        )
      end
      return result
    end

    local cache_hit = cache[arg1]
    if cache_hit then return cache_hit end

    local result = love.graphics.newImageRaw(arg1)
    cache[arg1] = result
    return result
  end
end

wrap("graphics", "newQuad")
wrap("graphics", "newFont", true)
wrap("graphics", "newSpriteBatch")
wrap("graphics", "newCanvas")
