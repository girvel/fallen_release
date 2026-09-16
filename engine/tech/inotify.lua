local ffi = require("ffi")
local inotify = {}

local inotify_fd, watch_fd, buffer

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

  watch_fd = ffi.C.inotify_add_watch(inotify_fd, ".", IN_CLOSE_WRITE)
  assert(watch_fd >= 0)

  buffer = ffi.new("char[4096]")
end

--- @class inotify.event
--- @field name ffi.cdata*
--- @field len integer

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
      table.insert(result, ffi.string(event.name))
      ptr = ptr + ffi.sizeof("struct inotify_event") + event.len
    end
  end

  return result
end

Ldump.mark(inotify, {}, ...)
return inotify
