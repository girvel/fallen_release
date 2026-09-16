local ui = require("engine.tech.ui")
local ffi = require("ffi")
local inotify = {}

local get_subdirectories_recursively

--- @param base string
--- @param result? string[]
--- @return string[]
get_subdirectories_recursively = function(base, result)
  result = result or {}
  table.insert(result, base)

  local info = {}
  if base == "." then
    for _, entry in ipairs(love.filesystem.getDirectoryItems("")) do
      if not entry:starts_with(".")
        and love.filesystem.getRealDirectory(entry) ~= love.filesystem.getSaveDirectory()
        and love.filesystem.getInfo(entry, "directory", info)
      then
        get_subdirectories_recursively(entry, result)
      end
    end
  else
    for _, entry in ipairs(love.filesystem.getDirectoryItems(base)) do
      local entry_full_path = base.."/"..entry
      if not entry:starts_with(".")
        and love.filesystem.getInfo(entry_full_path, "directory", info)
      then
        get_subdirectories_recursively(entry_full_path, result)
      end
    end
  end
  return result
end

local is_available do
  local cache
  is_available = function()
    if cache == nil then
      cache = love.system.getOS() == "Linux"
    end
    return cache
  end
end

local inotify_fd, fd_to_dir, buffer

local init = function()
  ffi.cdef [[
    int inotify_init1(int flags);
    int inotify_add_watch(int fd, const char *pathname, uint32_t mask);
    int inotify_rm_watch(int fd, int wd);
    ssize_t read(int fd, void *buf, size_t count);

    struct inotify_event {
        int      wd;       /* Watch descriptor (matches what add_watch returned) */
        uint32_t mask;     /* Mask describing the event that occurred */
        uint32_t cookie;   /* Unique cookie tying related events together (like renames) */
        uint32_t len;      /* Length of the 'name' array that follows */
        char     name[];   /* Variable-length null-terminated file name */
    };
  ]]

  local IN_NONBLOCK = 2048
  local IN_CLOSE_WRITE = 8

  inotify_fd = ffi.C.inotify_init1(IN_NONBLOCK)
  assert(inotify_fd >= 0)

  fd_to_dir = {}
  for _, dir in ipairs(get_subdirectories_recursively(".")) do
    if dir == "" then dir = "." end
    local watch_fd = ffi.C.inotify_add_watch(inotify_fd, dir, IN_CLOSE_WRITE)
    assert(watch_fd >= 0)
    fd_to_dir[watch_fd] = dir
  end

  buffer = ffi.new("char[4096]")
end

--- @class inotify.event
--- @field name ffi.cdata*
--- @field len integer
--- @field wd integer

--- @return string[]
--- @nodiscard
inotify.get_changed_files = function()
  if not inotify_fd then init() end

  local result = {}
  local bytes_read = ffi.C.read(inotify_fd, buffer, ffi.sizeof(buffer))
  if bytes_read > 0 then
    local base = ffi.cast("char *", buffer)
    local ptr = base
    while ptr < base + bytes_read do
      local event = ffi.cast("struct inotify_event *", ptr) --[[@as inotify.event]]
      table.insert(result, fd_to_dir[event.wd].."/"..ffi.string(event.name))
      ptr = ptr + ffi.sizeof("struct inotify_event") + event.len
    end
  end

  return result
end

--- @type table<table, {container: table, key: string, modpath: string}>
local module_map = setmetatable({}, {__mode = "k"})

--- @param modpath string
--- @param base table
--- @param key any
--- @return any
inotify.require = function(modpath, base, key)
  local result = require(modpath)
  if not is_available() then return result end

  key = key or assert(modpath:match("%.?([^%.]+)$"))
  module_map[result] = {
    container = base,
    key = key,
    modpath = modpath,
  }
  Ldump.serializer.handlers[result] = function()
    return inotify.require(modpath, base, key)
  end
  return result
end

inotify.update = function()
  if not is_available() then return end

  local changed_files = {}
  local modules_changed = false
  local images_changed = false
  for _, file in ipairs(inotify.get_changed_files()) do
    if file:ends_with(".lua") then
      modules_changed = true
      changed_files[file] = true
    elseif file:ends_with(".png") then
      images_changed = true
    end
  end

  if images_changed then
    --- @diagnostic disable-next-line:undefined-field
    love.graphics.newImageCache.children = nil
    ui.reset_caches()
  end

  if modules_changed then
    for prev_mod, params in pairs(module_map) do
      if changed_files[Common.posix_path(params.modpath)] then
        Log.info("Reloaded %s", params.modpath)
        package.loaded[params.modpath] = nil
        local mod = require(params.modpath)
        module_map[mod] = params
        params.container[params.key] = mod
        Ldump.serializer.handlers[mod] = Ldump.serializer.handlers[prev_mod]
      end
    end
  end
end

Ldump.mark(inotify, {}, ...)
return inotify
