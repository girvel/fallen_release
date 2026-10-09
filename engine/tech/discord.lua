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

local state = {}

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
      state.details = "Пилит \""..last_commit.."\", что бы это ни было"
    else
      state.details = "Пилит движок"
    end
  else
    state.details = "Гоняет пиратку"
  end

  state.button1_label = button1_label
  state.button1_url = button1_url
  state.button2_label = button2_label
  state.button2_url = button2_url
  state.startTimestamp = os.time()
  
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

local sync_presence = function()
  local presence = ffi.new("struct DiscordRichPresence")
  presence.state = state.state
  presence.details = state.details
  presence.startTimestamp = state.startTimestamp
  presence.button1_label = state.button1_label
  presence.button1_url = state.button1_url
  presence.button2_label = state.button2_label
  presence.button2_url = state.button2_url
  c_lib.Discord_UpdatePresence(presence)
end

--- @param status string?
discord.set_status = function(status)
  local STATUS_LEN = 127
  if #status > STATUS_LEN then
    Error("Discord status should be %s characters max; %q is excessive",
          STATUS_LEN, status:sub(STATUS_LEN + 1))
    status = status:sub(1, STATUS_LEN)
  end

  state.state = status
  sync_presence()
  Log.info("Pushed Discord presence status %q", status)
end

-- Calls lua callbacks passed to C code => should not be compiled
jit.off(discord.update)

Ldump.mark(discord, {}, ...)
return discord