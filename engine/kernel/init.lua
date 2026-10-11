local dynamic_canvas = require("engine.tech.dynamic_canvas")


local kernel = {}

--- @class kernel.config
--- @field discord_status string

--- @class kernel middleware between fallen engine and LOVE
--- @field gui gui
--- @field overlay debug_overlay
--- @field args table CLI args
--- @field config kernel.config|table
--- @field debug boolean
--- @field frame_n integer
--- @field cpu_time number
--- @field start_time number
--- @field screenshot love.Canvas
--- @field _save? string
--- @field _specific_key_rates table<love.KeyConstant, number>
--- @field _delays table<love.KeyConstant, number>
--- @field _is_active boolean
local methods = {}
local mt = {__index = methods}

--- @param args table
--- @return kernel
kernel.new = function(args)
  local result = {
    gui = require("engine.gui").new(),
    overlay = require("engine.kernel.debug_overlay").new(args.debug and not args.youtube),
    args = args,
    config = {},
    debug = args.debug,
    frame_n = 0,
    cpu_time = 0,
    start_time = 0,
    _specific_key_rates = {},
    _delays = {},
    _is_active = false,
  }

  if love.filesystem.getInfo("config.lua", "file") then
    result.config = assert(love.filesystem.load("config.lua"))()
    Log.info("Found kernel config: %s", Inspect(result.config))
  else
    Log.info("Found no kernel config")
  end

  result.screenshot = dynamic_canvas.new(result, "screenshot")
  return setmetatable(result, mt)
end

--- @param name string
methods.plan_save = function(self, name)
  self._save = "saves/" .. name .. ".ldump.gz"
end

--- @param key love.KeyConstant
--- @param value number
methods.set_key_rate = function(self, key, value)
  self._specific_key_rates[key] = value
end

local DEFAULT_KEY_RATE = 5

--- @param key love.KeyConstant
--- @return number
methods.get_key_rate = function(self, key)
  return self._specific_key_rates[key] or DEFAULT_KEY_RATE
end

methods.report = function(self)
  if Kernel.args.profiler then
    Log.info(Profile.report(100))
  end

  local line_report = Lp.report()
  if #line_report > 0 then
    Log.info("Line profile:\n%s", line_report)
  end

  Log.info("Play time %s s, average FPS is %.2f", math.floor(love.timer.getTime() - self.start_time), self.frame_n / self.cpu_time)
  Log.info("Saved log to %s/%s", love.filesystem.getRealDirectory(Log.outfile), Log.outfile)
  Log.report()
end

return kernel
