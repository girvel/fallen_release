require("engine.kernel.main")
local ffi_fix = require("engine.tech.ffi_fix")
local discord_rpc = ffi_fix.load("discord-rpc")
Log.trace(discord_rpc)