local ffi = require("ffi")
local ffi_fix = require("engine.tech.ffi_fix")
local discord = {}

local c_lib = ffi_fix.load("discord-rpc")
ffi.cdef [[
typedef struct DiscordRichPresence {
    const char* state;   /* max 128 bytes */
    const char* details; /* max 128 bytes */
    int64_t startTimestamp;
    int64_t endTimestamp;
    const char* largeImageKey;               /* max 32 bytes */
    const char* largeImageText;              /* max 128 bytes */
    const char* smallImageKey;               /* max 32 bytes */
    const char* smallImageText;              /* max 128 bytes */
    const char* partyId;                     /* max 128 bytes */
    const char *button1_label, *button1_url; /* max 128 bytes */
    const char *button2_label, *button2_url; /* max 128 bytes */
    int partySize;
    int partyMax;
    int partyPrivacy;
    const char* matchSecret;    /* max 128 bytes */
    const char* joinSecret;     /* max 128 bytes */
    const char* spectateSecret; /* max 128 bytes */
    int8_t instance;
} DiscordRichPresence;

typedef struct DiscordUser {
    const char* userId;
    const char* username;
    const char* discriminator;
    const char* avatar;
} DiscordUser;

typedef void (*readyPtr)(const DiscordUser* request);
typedef void (*disconnectedPtr)(int errorCode, const char* message);
typedef void (*erroredPtr)(int errorCode, const char* message);
typedef void (*joinGamePtr)(const char* joinSecret);
typedef void (*spectateGamePtr)(const char* spectateSecret);
typedef void (*joinRequestPtr)(const DiscordUser* request);

typedef struct DiscordEventHandlers {
    readyPtr ready;
    disconnectedPtr disconnected;
    erroredPtr errored;
    joinGamePtr joinGame;
    spectateGamePtr spectateGame;
    joinRequestPtr joinRequest;
} DiscordEventHandlers;

void Discord_Initialize(const char* applicationId,
                        DiscordEventHandlers* handlers,
                        int autoRegister,
                        const char* optionalSteamId);
void Discord_Shutdown(void);
void Discord_RunCallbacks(void);
void Discord_UpdatePresence(const DiscordRichPresence* presence);
]]

local presence_state = ffi.new("struct DiscordRichPresence")
presence_state.state = "Катает"
presence_state.details = "..."
presence_state.button1_label = "Дискорд конфа"
presence_state.button1_url = "https://discord.gg/9G7VD9bqMy"

--- @param application_id string
--- @param button1_label? string
--- @param button1_url? string
--- @param button2_label? string
--- @param button2_url? string
discord.init = function(application_id, top_line,
                        button1_label, button1_url,
                        button2_label, button2_url)
  if type(application_id) ~= "string" then
    Error("Expected application_id to be string, got %s", type(application_id))
    return
  end
  
  if love.filesystem.getInfo("main.lua", "file") then
    local last_commit do
      local f = assert(io.popen("git log -1 --pretty=%s"))
      last_commit = f:read("*a")
      if not f:close() then
        last_commit = nil
      end
    end
    
    if last_commit then
      presence_state.details = "Пилит \""..last_commit.."\", что бы это ни было"
    else
      presence_state.details = "Пилит движок"
    end
  else
    presence_state.details = "Гоняет пиратку"
  end

  presence_state.button1_label = button1_label
  presence_state.button1_url = button1_url
  presence_state.button2_label = button2_label
  presence_state.button2_url = button2_url
  
  local eventHandlers = ffi.new("struct DiscordEventHandlers")
  eventHandlers.errored = ffi.cast("erroredPtr", function(error_code, message)
    Log.error("Discord RPC error #%s: %s", error_code, ffi.string(message))
  end)
  eventHandlers.ready = ffi.cast("readyPtr", function(request)
    Log.info("Discord ready; user %s, ID %s",
             ffi.string(request.username), ffi.string(request.userId))
  end)
  eventHandlers.disconnected = ffi.cast("disconnectedPtr", function(error_code, message)
    Log.info("Discord disconnect; #%s, %s", error_code, ffi.string(message))
  end)
  
  c_lib.Discord_Initialize(tostring(application_id), eventHandlers, 1, nil)
  Log.info("Initialized Discord RPC")
end

discord.deinit = function()
  c_lib.Discord_Shutdown()
end

discord.update = function()
  c_lib.Discord_RunCallbacks()
end

--- @param status string?
discord.set_status = function(status)
  if presence_state.startTimestamp == 0 then
    presence_state.startTimestamp = os.time()
  end
  presence_state.state = status
  c_lib.Discord_UpdatePresence(presence_state)
  Log.info("Pushed Discord presence status %q", status)
end

-- Calls lua callbacks passed to C code => should not be compiled
jit.off(discord.update)

Ldump.mark(discord, {}, ...)
return discord