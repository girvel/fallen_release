local ffi = require("ffi")


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

local inotify_fd = ffi.C.inotify_init1(IN_NONBLOCK)
assert(inotify_fd >= 0)

local watch_fd = ffi.C.inotify_add_watch(inotify_fd, ".", IN_CLOSE_WRITE)
assert(watch_fd >= 0)

local BUFFER_SIZE = 4096
local buffer = ffi.new("char["..BUFFER_SIZE.."]")
while true do
  os.execute("sleep 0.1s")

  local bytes_read = ffi.C.read(inotify_fd, buffer, BUFFER_SIZE)
  if bytes_read <= 0 then goto continue end

  local base = ffi.cast("char *", buffer)
  local ptr = base
  while ptr < base + bytes_read do
    local event = ffi.cast("struct inotify_event *", ptr)
    print(ffi.string(event.name))
    ptr = ptr + ffi.sizeof("struct inotify_event") + event.len
  end
  break

  ::continue::
end
