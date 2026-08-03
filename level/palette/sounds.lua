local sound = require("engine.tech.sound")
local sounds = {}

sounds.engine = function()
  return sound.source("assets/sounds/engine.mp3", 1, "medium")
end

sounds.engine_electricity = function()
  return sound.source("assets/sounds/engine_electricity.mp3", .2, "medium")
end

sounds.bow_wave = function()
  return sound.source("assets/sounds/bow_wave.mp3", .7, "medium")
end

Ldump.mark(sounds, {}, ...)
return sounds
