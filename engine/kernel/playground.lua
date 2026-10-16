local ffi = require("ffi")
local ffi_fix = require("engine.tech.ffi_fix")

ffi.cdef[[
  typedef double dReal;
  typedef void* dWorldID;

  void dInitODE();
  dWorldID dWorldCreate();
  void dWorldDestroy(dWorldID world);
  void dCloseODE();
]]

local ode = ffi_fix.load("libode")

if not ode then
  Log.fatal("Failed to load libode.so! Check if it's in engine/lib/")
  return
end

Log.info("Initializing ODE...")
ode.dInitODE()

Log.info("Creating physics world...")
local world = ode.dWorldCreate()

if world ~= nil then
  Log.info("Success! ODE World created at pointer: %s", tostring(world))
else
  Log.error("Failed to create ODE World!")
end

ode.dWorldDestroy(world)
ode.dCloseODE()
Log.info("ODE cleanly shut down.")
