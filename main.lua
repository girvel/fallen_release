require("engine.kernel.main")
local ffi_fix = require("engine.tech.ffi_fix")
local discord_rpc = require("engine.lib.discordRPC")
discord_rpc.initialize("1282966796533501953", true)
discord_rpc.ready = function(userId, username)
  Log.info("Discord ready; user %s, ID %s", username, userId)
end
discord_rpc.disconnected = function(error_code, message)
  Log.info("Discord disconnect; #%s, %s", error_code, ffi.string(message))
end
discord_rpc.errored = function(error_code, message)
  Log.error("Discord RPC error #%s: %s", error_code, ffi.string(message))
end
discord_rpc.updatePresence({
	state = "Testing the Update Presence",
	details = "...",
	
	startTimestamp = os.time(),
	
	button1_label = "Write to the Developer",
	button1_url = "https://t.me/girvel",
})