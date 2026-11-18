--- Module for storing and producing sounds
---
--- Wraps LOVE functions in a convenient API; also, implements serializion of dynamically changed
--- sources.
local sound = {}

--- @alias sound_event "hit"|"walk"

--- @class sound
--- @field source love.Source?
--- @field _path string
--- @field _volume number
--- @field _can_be_missing boolean
local methods = {}
local mt = {__index = methods}

sound.cache = CompositeMap.new("weak")

--- @param path string
sound._read_source = function(path)
  local mnt_path = "mnt/"..path:strip_prefix("engine/")
  if not love.filesystem.getInfo(mnt_path, "file") then
    if not love.filesystem.getInfo(path, "file") then
      return nil
    end
    return love.audio.newSource(path, "static")
  end
  return love.audio.newSource(mnt_path, "static")
end

-- TODO sound nor sound.multiple should not be immutable

-- NOTICE should not be cached, mutable

--- @param path string
--- @param volume? number
--- @param can_be_missing? boolean
--- @return sound
sound.new = function(path, volume, can_be_missing)
  local source = sound._read_source(path)
  if source then
    if volume then source:setVolume(volume) end
    if source:getChannelCount() == 1 then
      source:setRelative(true)
    end
  elseif not can_be_missing then
    Error("Missing audio file %s", path)
  end
  return setmetatable({
    source = source,
    _path = path,
    _volume = volume,
    _can_be_missing = can_be_missing,
  }, mt)
end

--- @class sound_multiple: { [integer]: sound }
local multiple_methods = {}
local multiple_mt = {__index = multiple_methods}

--- Load all sounds from a directory
--- @param dir_path string
--- @param volume? number
--- @return sound_multiple
sound.multiple = function(dir_path, volume)
  if not love.filesystem.getInfo(dir_path) then
    Error("%q doesn't exist", dir_path)
    return setmetatable({}, multiple_mt)
  end

  local result = setmetatable(
    Fun.iter(love.filesystem.getDirectoryItems(dir_path))
      :map(function(path) return sound.new(dir_path .. "/" .. path, volume) end)
      :totable(),
    multiple_mt
  )

  if #result == 0 then
    Error("%q is empty", dir_path)
  end

  return result
end

--- @param path string
--- @param volume? number
--- @param size? sound_size
sound.source = function(path, volume, size)
  return {
    sound_source = sound.new(path, volume):clone(),
    on_add = function(self)
      self.sound_source:place(self.position, size):set_looping(true):play()
    end,
    on_remove = function(self)
      self.sound_source:stop()
    end,
  }
end

--- @enum (key) sound_size
sound.sizes = {
  small = {2, 10},
  medium = {7, 20},
  large = {15, 30},
}

--- Creates a fully independent copy of the sound
--- @param self sound
--- @return sound
methods.clone = function(self)
  return setmetatable({
    source = self.source and self.source:clone(),
    _path = self._path,
    _volume = self._volume,
    _can_be_missing = self._can_be_missing,
  }, mt)
end

--- @generic T: sound
--- @param self T
--- @param position vector
--- @param size? sound_size
--- @return T
methods.place = function(self, position, size)
  --- @cast self sound
  if not self.source then return self end

  local limits = sound.sizes[size or "small"]
  if not limits then
    Error("Incorrect sound size %s; sounds can be small, medium or large", size)
  end

  self.source:setRelative(false)
  self.source:setPosition(unpack(position))
  self.source:setAttenuationDistances(unpack(limits))
  self.source:setRolloff(2)
  return self
end

--- @generic T: sound
--- @param self T
--- @return T
methods.play = function(self)
  --- @cast self sound
  if not self.source then return self end
  if not State.player or not State.model.is_deaf then self.source:play() end
  return self
end

--- @generic T: sound
--- @param self T
--- @return T
methods.stop = function(self)
  --- @cast self sound
  if self.source then self.source:stop() end
  return self
end

mt.__serialize = function(self)
  local path = self._path
  local volume = self._volume
  local can_be_missing = self._can_be_missing
  local looping = self.source:isLooping()
  local relative, x, y, rolloff, ref, max
  if self.source:getChannelCount() == 1 then
    relative = self.source:isRelative()
    x, y = self.source:getPosition()
    rolloff = self.source:getRolloff()
    ref, max = self.source:getAttenuationDistances()
  end

  return function()
    local result = sound.new(path, volume, can_be_missing)
    if result.source then
      result.source:setLooping(looping or false)
      if result.source:getChannelCount() == 1 then
        result.source:setRelative(relative)
        result.source:setPosition(x, y, 0)
        result.source:setRolloff(rolloff)
        result.source:setAttenuationDistances(ref, max)
      end
    end
    return result
  end
end

--- @generic T: sound
--- @param self T
--- @param value boolean
--- @return T
methods.set_looping = function(self, value)
  --- @cast self sound
  if self.source then self.source:setLooping(value) end
  return self
end

--- @param position vector
--- @param size? sound_size
multiple_methods.play_at = function(self, position, size)
  return Random.item(self):clone():place(position, size):play()
end

--- @return sound
multiple_methods.play = function(self)
  return Random.item(self):clone():play()
end

Ldump.mark(sound, {}, ...)
return sound
