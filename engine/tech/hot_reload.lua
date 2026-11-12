local ffi = require("ffi")
local hot_reload = {is_reloading = false}

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

local os_name = love.system.getOS()

local is_available do
  local allowed_oses = {
    Linux = true,
    Windows = true,
  }

  is_available = allowed_oses[os_name]
    and not Common.is_game_built()
    and os.getenv("NO_HOTRELOAD") ~= "1"

  if is_available then
    Log.info("Hot reloading enabled")
  else
    Log.info("Hot reloading unavailable")
  end
end

local is_initialized, init
if os_name == "Linux" then
  local inotify_fd, fd_to_dir, buffer

  init = function()
    is_initialized = true
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
    if inotify_fd < 0 then
      error("inotify_init1 failed")
    end

    fd_to_dir = {}
    for _, dir in ipairs(get_subdirectories_recursively(".")) do
      if dir == "" then dir = "." end
      local watch_fd = ffi.C.inotify_add_watch(inotify_fd, dir, IN_CLOSE_WRITE)
      if watch_fd < 0 then
        error("inotify_add_watch failed")
      end
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
  hot_reload.get_changed_files = function()
    if not is_initialized then init() end

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
elseif os_name == "Windows" then
  local dir_handle, event_handle, buffer, buffer_size, overlapped
  
  local CP_UTF8 = 65001
  
  local to_utf16 = function(str)
    local wlen = ffi.C.MultiByteToWideChar(CP_UTF8, 0, str, #str, nil, 0)
    if wlen == 0 then return nil end
    local buf = ffi.new("wchar_t[?]", wlen + 1)
    ffi.C.MultiByteToWideChar(CP_UTF8, 0, str, #str, buf, wlen)
    buf[wlen] = 0
    return buf
  end
  
  local from_utf16 = function(wptr, byte_len)
    local wchar_count = math.floor(byte_len / 2)
    if wchar_count == 0 then return "" end
    local len = ffi.C.WideCharToMultiByte(CP_UTF8, 0, wptr, wchar_count, nil, 0, nil, nil)
    if len == 0 then return "" end
    local buf = ffi.new("char[?]", len)
    ffi.C.WideCharToMultiByte(CP_UTF8, 0, wptr, wchar_count, buf, len, nil, nil)
    return ffi.string(buf, len)
  end
  
  local FILE_NOTIFY_CHANGE_FILE_NAME = 0x01
  local FILE_NOTIFY_CHANGE_SIZE = 0x08
  local FILE_NOTIFY_CHANGE_LAST_WRITE = 0x10
  
  local request = function()
    ffi.C.ResetEvent(event_handle)
    local ok = ffi.C.ReadDirectoryChangesW(
      dir_handle,
      buffer, buffer_size,
      1,
      bit.bor(
        FILE_NOTIFY_CHANGE_LAST_WRITE,
        FILE_NOTIFY_CHANGE_SIZE,
        FILE_NOTIFY_CHANGE_FILE_NAME
      ),
      nil,
      overlapped,
      nil
    )
    
    if ok == 0 then
      error("ReadDirectoryChangesW error: "..tostring(ffi.C.GetLastError()))
    end
  end
  
  init = function()
    is_initialized = true
    ffi.cdef [[
      typedef void* HANDLE;
      typedef unsigned long DWORD;
      typedef unsigned short WORD;
      typedef unsigned char BYTE;
      typedef int BOOL;
      typedef const wchar_t* LPCWSTR;
      typedef wchar_t* LPWSTR;
      typedef const char* LPCSTR;
      typedef char* LPSTR;
      typedef size_t ULONG_PTR;

      typedef struct {
        ULONG_PTR Internal;
        ULONG_PTR InternalHigh;
        union {
          struct {
            DWORD Offset;
            DWORD OffsetHigh;
          };
          void* Pointer;
        };
        HANDLE hEvent;
      } OVERLAPPED;

      typedef struct {
        DWORD NextEntryOffset;
        DWORD Action;
        DWORD FileNameLength;
        wchar_t FileName[1];
      } FILE_NOTIFY_INFORMATION;

      HANDLE CreateFileW(
        LPCWSTR lpFileName,
        DWORD dwDesiredAccess,
        DWORD dwShareMode,
        void* lpSecurityAttributes,
        DWORD dwCreationDisposition,
        DWORD dwFlagsAndAttributes,
        HANDLE hTemplateFile
      );

      HANDLE CreateEventW(
        void* lpEventAttributes,
        BOOL bManualReset,
        BOOL bInitialState,
        LPCWSTR lpName
      );

      BOOL ReadDirectoryChangesW(
        HANDLE hDirectory,
        void* lpBuffer,
        DWORD nBufferLength,
        BOOL bWatchSubtree,
        DWORD dwNotifyFilter,
        DWORD* lpBytesReturned,
        OVERLAPPED* lpOverlapped,
        void* lpCompletionRoutine
      );

      BOOL GetOverlappedResult(
        HANDLE hFile,
        OVERLAPPED* lpOverlapped,
        DWORD* lpNumberOfBytesTransferred,
        BOOL bWait
      );

      DWORD WaitForSingleObject(HANDLE hHandle, DWORD dwMilliseconds);
      BOOL ResetEvent(HANDLE hEvent);
      BOOL CancelIo(HANDLE hFile);
      BOOL CloseHandle(HANDLE hObject);
      DWORD GetLastError(void);

      int MultiByteToWideChar(
        unsigned int CodePage,
        DWORD dwFlags,
        LPCSTR lpMultiByteStr,
        int cbMultiByte,
        LPWSTR lpWideCharStr,
        int cchWideChar
      );

      int WideCharToMultiByte(
        unsigned int CodePage,
        DWORD dwFlags,
        LPCWSTR lpWideCharStr,
        int cchWideChar,
        LPSTR lpMultiByteStr,
        int cbMultiByte,
        LPCSTR lpDefaultChar,
        BOOL* lpUsedDefaultChar
      );
    ]]
    
    local wpath = to_utf16(".")
    if not wpath then
      error("Converting path to utf16 failed")
    end
    
    local FILE_LIST_DIRECTORY = 0x1
    local FILE_SHARE_READ = 0x1
    local FILE_SHARE_WRITE = 0x2
    local FILE_SHARE_DELETE = 0x4
    local FILE_FLAG_BACKUP_SEMANTICS = 0x02000000
    local FILE_FLAG_OVERLAPPED = 0x40000000
    local OPEN_EXISTING = 3
    
    dir_handle = ffi.C.CreateFileW(
      wpath,
      FILE_LIST_DIRECTORY,
      bit.bor(FILE_SHARE_READ, FILE_SHARE_WRITE, FILE_SHARE_DELETE),
      nil,
      OPEN_EXISTING,
      bit.bor(FILE_FLAG_BACKUP_SEMANTICS, FILE_FLAG_OVERLAPPED),
      nil
    )
    
    local INVALID_HANDLE_VALUE = ffi.cast("HANDLE", -1)
    
    if dir_handle == INVALID_HANDLE_VALUE then
      error("CreateFileW failed with error: "..tostring(ffi.C.GetLastError()))
    end
    
    event_handle = ffi.C.CreateEventW(nil, 1, 0, nil)
    if event_handle == nil then
      ffi.C.CloseHandle(dir_handle)
      error("CreateEventW failed with error: "..tostring(ffi.C.GetLastError()))
    end
  
    buffer_size = 65536  -- 64 KB
    buffer = ffi.new("DWORD[?]", buffer_size / 4)
    overlapped = ffi.new("OVERLAPPED")
    overlapped.hEvent = event_handle
    
    request()
  end
  
  --- @return string[]
  --- @nodiscard
  hot_reload.get_changed_files = function()
    if not is_initialized then init() end

    local result = {}
    local wait_status = ffi.C.WaitForSingleObject(event_handle, 0)
    local WAIT_OBJECT_0 = 0
    if wait_status ~= WAIT_OBJECT_0 then
      return result
    end
    
    local bytes_returned = ffi.new("DWORD[1]")
    local ok = ffi.C.GetOverlappedResult(dir_handle, overlapped, bytes_returned, 0)
    if ok == 0 then
      local err = ffi.C.GetLastError()
      request()
      Log.error("GetOverlappedResult error: %s", err)
      return result
    end
    
    local bytes = bytes_returned[0]
    if bytes == 0 then
      Log.error("Internal windows buffer overflow")
      request()
      return result
    end
    
    local base_ptr = ffi.cast("uint8_t*", buffer)
    local offset = 0
    while true do
      local info = ffi.cast("FILE_NOTIFY_INFORMATION*", base_ptr + offset)
      local name = from_utf16(info.FileName, info.FileNameLength)
        :gsub("\\", "/")
      if not Table.contains(result, name) then
        table.insert(result, name)
      end
      if info.NextEntryOffset == 0 then
        break
      end
      offset = offset + info.NextEntryOffset
    end

    request()
    return result
  end
end

--- @type table<table, {container: table, key: string, modpath: string}>
local contained = setmetatable({}, {__mode = "k"})

--- @type table<string, table>
local marked = setmetatable({}, {__mode = "v"})

--- @type table<string, table>
local marked_as_containing_assets = setmetatable({}, {__mode = "v"})

--- @param modpath string
--- @param base table
--- @param key any
--- @return any
hot_reload.require = function(modpath, base, key)
  local result = require(modpath)
  assert(type(result) == "function", "hot_reload.require is indended for functions only")
  if not is_available then return result end

  key = key or assert(modpath:match("%.?([^%.]+)$"))
  contained[result] = {
    container = base,
    key = key,
    modpath = modpath,
  }
  Ldump.serializer.handlers[result] = function()
    return hot_reload.require(modpath, base, key)
  end
  return result
end

--- @param value table
--- @param modpath string
hot_reload.mark = function(value, modpath)
  if hot_reload.is_reloading then return end
  marked[modpath] = value
end

--- @param value table
--- @param modpath string
hot_reload.mark_as_containing_assets = function(value, modpath)
  if hot_reload.is_reloading then return end
  marked_as_containing_assets[modpath] = value
end

hot_reload.update = function()
  if not is_available then return end

  local changed_files = {}
  local modules_changed = false
  local images_changed = false
  for _, file in ipairs(hot_reload.get_changed_files()) do
    if file:ends_with(".lua") then
      modules_changed = true
      changed_files[file] = true
    elseif file:ends_with(".png") then
      images_changed = true
    end
  end

  if images_changed then
    local ui = require("engine.tech.ui")
    hot_reload.is_reloading = true

    --- @diagnostic disable-next-line:undefined-field
    Table.clear(love.graphics.newImageCache)
    ui.reset_caches()
    Log.info("Reloaded images")
    for modpath, prev_mod in pairs(marked_as_containing_assets) do
      package.loaded[modpath] = nil
      local ok, res = pcall(require, modpath)
      if ok then
        Log.info("Reloaded %s", modpath)
        Table.clear(prev_mod)
        for k, v in pairs(res) do
          prev_mod[k] = v
        end
      else
        Log.error("Error reloading %s: %s", modpath, res)
      end
      package.loaded[modpath] = prev_mod
    end
    hot_reload.is_reloading = false
  end

  if modules_changed then
    hot_reload.is_reloading = true

    for prev_mod, params in pairs(contained) do
      if changed_files[Common.posix_path(params.modpath)] then
        package.loaded[params.modpath] = nil
        local ok, res = pcall(require, params.modpath)
        if ok then
          Log.info("Reloaded %s", params.modpath)
          contained[res] = params
          params.container[params.key] = res
          Ldump.serializer.handlers[res] = Ldump.serializer.handlers[prev_mod]
        else
          Log.error("Error reloading %s: %s", params.modpath, res)
          package.loaded[params.modpath] = prev_mod
        end
      end
    end

    for modpath, prev_mod in pairs(marked) do
      if changed_files[Common.posix_path(modpath)] then
        package.loaded[modpath] = nil
        local ok, res = pcall(require, modpath)
        if ok then
          Log.info("Reloaded %s", modpath)
          Table.clear(prev_mod)
          for k, v in pairs(res) do
            prev_mod[k] = v
          end
        else
          Log.error("Error reloading %s: %s", modpath, res)
        end
        package.loaded[modpath] = prev_mod
      end
    end

    hot_reload.is_reloading = false
  end
end

Ldump.mark(hot_reload, {
  update = {
    marked = {},
    contained = {},
  },
}, ...)
return hot_reload
