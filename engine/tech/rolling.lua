local ffi_fix = require("engine.tech.ffi_fix")
local ffi = require("ffi")
local rolling = {}

ffi.cdef [[
  typedef float dReal;
  typedef void* dWorldID;
  typedef void* dSpaceID;
  typedef void* dBodyID;
  typedef void* dGeomID;
  typedef void* dJointGroupID;
  typedef void* dJointID;
  typedef void* dTriMeshDataID;

  // Structs required for creating the temporary Contact Joints
  typedef struct dMass {
    dReal mass;
    dReal c[4];
    dReal I[12];
  } dMass;

  typedef struct dSurfaceParameters {
    int mode;
    dReal mu, mu2, rho, rho2, rhoN;
    dReal bounce, bounce_vel;
    dReal soft_erp, soft_cfm;
    dReal motion1, motion2, motionN;
    dReal slip1, slip2;
  } dSurfaceParameters;

  typedef struct dContactGeom {
    dGeomID g1, g2;
    int side1, side2;
    dReal pos[4];
    dReal normal[4];
    dReal depth;
  } dContactGeom;

  typedef struct dContact {
    dSurfaceParameters surface;
    dContactGeom geom;
    dReal fdir1[3];
  } dContact;

  // Core API
  void dInitODE();
  void dCloseODE();
  dWorldID dWorldCreate();
  void dWorldDestroy(dWorldID world);
  void dWorldSetGravity(dWorldID, dReal x, dReal y, dReal z);
  void dWorldQuickStep(dWorldID, dReal stepsize);
  void dWorldStep(dWorldID world, dReal stepsize);

  // Spaces and Geoms (Collision)
  dSpaceID dHashSpaceCreate(dSpaceID space);
  void dSpaceDestroy(dSpaceID);
  dGeomID dCreatePlane(dSpaceID space, dReal a, dReal b, dReal c, dReal d);
  dGeomID dCreateSphere(dSpaceID space, dReal radius);
  void dSpaceCollide(dSpaceID space, void *data, void (*callback)(void *data, dGeomID o1, dGeomID o2));

  // Bodies (Physics)
  dBodyID dBodyCreate(dWorldID);
  void dGeomSetBody(dGeomID geom, dBodyID body);
  void dBodySetPosition(dBodyID, dReal x, dReal y, dReal z);
  void dBodySetLinearVel(dBodyID, dReal x, dReal y, dReal z);
  const dReal *dBodyGetPosition(dBodyID);
  const dReal *dBodyGetRotation(dBodyID);
  const dReal *dBodyGetLinearVel(dBodyID);
  const dReal *dBodyGetAngularVel(dBodyID);
  
  // Mass
  void dMassSetSphereTotal(dMass*, dReal total_mass, dReal radius);
  void dBodySetMass(dBodyID, const dMass* mass);

  // Joints
  dJointGroupID dJointGroupCreate(int max_size);
  void dJointGroupDestroy(dJointGroupID);
  void dJointGroupEmpty(dJointGroupID);
  int dCollide(dGeomID o1, dGeomID o2, int flags, dContactGeom *contact, int skip);
  dJointID dJointCreateContact(dWorldID, dJointGroupID, const dContact*);
  void dJointAttach(dJointID, dBodyID body1, dBodyID body2);
  
  dBodyID dGeomGetBody(dGeomID geom);
  dTriMeshDataID dGeomTriMeshDataCreate();
  void dGeomTriMeshDataBuildSingle(dTriMeshDataID g, 
                                   const void* Vertices, int VertexStride, int VertexCount, 
                                   const void* Indices, int IndexCount, int TriStride);
  dGeomID dCreateTriMesh(dSpaceID space, dTriMeshDataID Data,
                         void* Callback, void* ArrayCallback, void* RayCallback);
  void dGeomTriMeshDataPreprocess(dTriMeshDataID g);
  int dGeomTriMeshGetTriangleCount(dGeomID);
]]

local ode = ffi_fix.load("libode")
local world, space, contact_group, shader

local N = 1.9
local FOV = 1

local canvas_size = 4 * 32
local die_r = canvas_size / 2
local fall_h = 128
local die_r_meters = .5

local physics_to_graphics_scale = die_r_meters / die_r
local fall_h_meters = fall_h * physics_to_graphics_scale

rolling.init = function()
  ode.dInitODE()
  world = ode.dWorldCreate()
  ode.dWorldSetGravity(world, 0, 0, -9.81)
  space = ode.dHashSpaceCreate(nil)
  contact_group = ode.dJointGroupCreate(0)
  ode.dCreatePlane(space, 0, 0, 1, 0)

  -- NEXT shader to a separate file?
  shader = love.graphics.newShader [[
    #extension GL_OES_standard_derivatives : enable
    uniform mat4 model;
    uniform mat4 view;
    uniform mat4 projection;

    varying vec3 v_barycentric;

    #ifdef VERTEX
    attribute vec3 VertexBarycentric;

    vec4 position(mat4 transform_projection, vec4 vertex_position) {
      v_barycentric = VertexBarycentric;
      return projection * view * model * vertex_position;
    }
    #endif

    #ifdef PIXEL
    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
      vec4 it = Texel(tex, texture_coords) * color;
      vec3 pixel_thickness = fwidth(v_barycentric);

      if (any(lessThan(v_barycentric, pixel_thickness / 2))) {
        return vec4(.9, .9, .9, 1);
      } else {
        return it;
      }
    }
    #endif
  ]]

  local w = canvas_size
  local h = canvas_size

  local fov = math.rad(FOV)
  local aspect = w / h
  local near, far = 1, 10000
  local f = 1 / math.tan(fov / 2)
  local projection = {
    f / aspect, 0, 0, 0,
    0, f, 0, 0,
    0, 0, (far + near) / (near - far), (2 * far * near) / (near - far),
    0, 0, -1, 0,
  }

  local view = {
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, -400,
    0, 0, 0, 1,
  }

  shader:send("projection", "row", projection)
  shader:send("view", "row", view)
end

local t = (1 + math.sqrt(5)) / 2  -- Golden ratio
local d20 = {
  texture = love.graphics.newImage("engine/assets/textures/d20.png"),

  vertices = {
    {-1,  t,  0},
    {1,  t,  0},
    {-1, -t,  0},
    {1, -t,  0},
    {0, -1,  t},
    {0,  1,  t},
    {0, -1, -t},
    {0,  1, -t},
    {t,  0, -1},
    {t,  0,  1},
    {-t,  0, -1},
    {-t,  0,  1}
  },

  texture_vertices = {
    {46, 83},
    {55, 68},
    {100, 83},
    {82, 53},
    {91, 68},
    {100, 53},
    {82, 83},
    {64, 83},
    {73, 68},
    {64, 53},
    {73, 98},
    {118, 83},

    {109, 68},
    {37, 68},
    {127, 68},
    {28, 83},
    {55, 98},
    {91, 98},
  },

  faces = {
    {12, 11, 3, 3, 18, 7},
    {2, 6, 10, 5, 6, 13},
    {11, 8, 7, 8, 11, 7},
    {4, 10, 5, 5, 9, 4},
    {6, 12, 5, 12, 13, 15},
    {4, 7, 9, 5, 7, 9},
    {1, 11, 12, 17, 8, 1},
    {8, 2, 9},
    {4, 3, 7, 5, 3, 7},
    {1, 2, 8, 2, 8, 1},
    {4, 5, 3, 3, 5, 13},
    {1, 6, 2, 1, 14, 2},
    {3, 5, 12, 3, 13, 12},
    {4, 9, 10, 9, 10, 4},
    {1, 12, 6, 1, 16, 14},
    {9, 7, 8, 8, 9, 7},
    {1, 8, 11, 17, 8, 11},
    {5, 10, 6, 5, 4, 6},
    {7, 3, 11, 7, 18, 11},
    {10, 9, 2},
  },
}

local k = .5 / math.sqrt(1 + t * t)
d20.ode_vertices = ffi.new("float[?]", #d20.vertices * 4)
for i, vertex in ipairs(d20.vertices) do
  d20.ode_vertices[(i - 1) * 4] = vertex[1] * k
  d20.ode_vertices[(i - 1) * 4 + 1] = vertex[2] * k
  d20.ode_vertices[(i - 1) * 4 + 2] = vertex[3] * k
  d20.ode_vertices[(i - 1) * 4 + 3] = 0
end

d20.ode_indices = ffi.new("int[?]", #d20.faces * 3)
for i, face in ipairs(d20.faces) do
  d20.ode_indices[(i - 1) * 3] = face[1] - 1
  d20.ode_indices[(i - 1) * 3 + 1] = face[2] - 1
  d20.ode_indices[(i - 1) * 3 + 2] = face[3] - 1
end

do
  local barycentrics = {
    {1, 0, 0},
    {0, 1, 0},
    {0, 0, 1},
  }

  local tw, th = d20.texture:getDimensions()

  d20.mesh_vertices = Table.new(#d20.faces * 3, 0)
  for _, face in ipairs(d20.faces) do
    for i = 1, 3 do
      local triangle_index = face[i]
      local b = barycentrics[i]
      local vertex = d20.vertices[triangle_index]
      local texture_vertex = d20.texture_vertices[face[i + 3] or triangle_index]
      table.insert(d20.mesh_vertices, {
        N * vertex[1],
        N * vertex[2],
        N * vertex[3],
        (texture_vertex[1] - .5) / tw,
        (texture_vertex[2] - .5) / th,
        unpack(b)
      })
    end
  end
end

local default_mesh_format = {
  {"VertexPosition", "float", 3},
  {"VertexTexCoord", "float", 2},
  {"VertexBarycentric", "float", 3},
}

local add_d20 = function()
  local mesh = love.graphics.newMesh(default_mesh_format, d20.mesh_vertices, "triangles", "static")
  mesh:setTexture(d20.texture)
  
  local body = ode.dBodyCreate(world)
  ode.dBodySetPosition(body, 1, 1, fall_h_meters)
  local v = Vector.one:rotate(math.random() * 2 * math.pi):mul_mut(50)
  ode.dBodySetLinearVel(body, v.x, v.y, 0)
  local mass = ffi.new("dMass")
  ode.dMassSetSphereTotal(mass, 1.0, die_r_meters)
  ode.dBodySetMass(body, mass)
  local tri_data = ode.dGeomTriMeshDataCreate()
  ode.dGeomTriMeshDataBuildSingle(
    tri_data, d20.ode_vertices, 4 * ffi.sizeof("float"), #d20.vertices,
    d20.ode_indices, #d20.faces * 3, 3 * ffi.sizeof("int")
  )
  ode.dGeomTriMeshDataPreprocess(tri_data)
  local die_geom = ode.dCreateTriMesh(space, tri_data, nil, nil, nil)
  ode.dGeomSetBody(die_geom, body)

  return {
    mesh = mesh,
    body = body,
  }
end

local collision_callback = ffi.cast("void (*)(void *, dGeomID, dGeomID)", function(data, a, b)
  local contacts = ffi.new("dContact[4]")
  local contacts_n = ode.dCollide(a, b, 4, contacts[0].geom, ffi.sizeof("dContact"))

  for i = 0, contacts_n - 1 do
    local contact = contacts[i]
    contact.surface.mode = 4
    contact.surface.mu = 50
    contact.surface.bounce = .4
    contact.surface.bounce_vel = .1

    local joint = ode.dJointCreateContact(world, contact_group, contact)
    ode.dJointAttach(joint, ode.dGeomGetBody(a), ode.dGeomGetBody(b))
  end
end)

--- @async
--- @param this_roll d.roll
--- @return integer
rolling.make = function(this_roll)
  do
    assert(#this_roll.dice == 1)
    assert(#this_roll.reroll == 0)
    local die = this_roll.dice[1]
    assert(die.sides_n == 20)
    assert(die.advantage == 0)
  end

  local die = add_d20()
  local w, h = love.graphics.getDimensions()
  ode.dCreatePlane(space, 1, 0, 0, 0)
  ode.dCreatePlane(space, -1, 0, 0, -w * physics_to_graphics_scale)
  ode.dCreatePlane(space, 0, 1, 0, 0)
  ode.dCreatePlane(space, 0, -1, 0, -h * physics_to_graphics_scale)

  local model = {
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1,
  }

  local die_canvas = love.graphics.newCanvas(canvas_size, canvas_size)
  local depth_canvas = love.graphics.newCanvas(canvas_size, canvas_size,
                                               {format = "depth16", readable = false})
  local canvas_pair = {die_canvas, depthstencil = depth_canvas}

  local rot

  while true do
    local dt = coroutine.yield()

    ode.dSpaceCollide(space, nil, collision_callback)
    ode.dWorldStep(world, dt)
    ode.dJointGroupEmpty(contact_group)
    local pos = ode.dBodyGetPosition(die.body)
    rot = ode.dBodyGetRotation(die.body)

    model[1] = rot[0]
    model[2] = rot[1]
    model[3] = rot[2]

    model[5] = rot[4]
    model[6] = rot[5]
    model[7] = rot[6]

    model[9] = rot[8]
    model[10] = rot[9]
    model[11] = rot[10]

    local prev_shader = love.graphics.getShader()
    love.graphics.setShader(shader)
    love.graphics.setDepthMode("less", true)
    shader:send("model", "row", model)

    local prev_canvas = love.graphics.getCanvas()
    love.graphics.setCanvas(canvas_pair)
    love.graphics.clear()

    love.graphics.draw(die.mesh)

    love.graphics.setDepthMode("always", false)
    love.graphics.setShader(prev_shader)
    love.graphics.setCanvas(prev_canvas)

    love.graphics.draw(
      die_canvas,
      math.floor(pos[0] / physics_to_graphics_scale - die_r),
      math.floor(pos[1] / physics_to_graphics_scale - die_r)
    )

    local linear_v = ode.dBodyGetLinearVel(die.body)
    local angular_v = ode.dBodyGetAngularVel(die.body)
    if math.abs(linear_v[0]) + math.abs(linear_v[1]) + math.abs(linear_v[2]) < .001
      and math.abs(angular_v[0]) + math.abs(angular_v[1]) + math.abs(angular_v[2]) < .001
    then
      break
    end
  end

  local key_min = math.huge
  local face_i = 10
  for i, face in ipairs(d20.faces) do
    local a = V(unpack(d20.vertices[face[1]]))
    local b = V(unpack(d20.vertices[face[2]]))
    local c = V(unpack(d20.vertices[face[3]]))

    local ab = b - a
    local ac = c - a

    local n = ab:cross(ac)

    -- Rotation matrix =
    -- [ rot[0]  rot[1]  rot[2]  ]
    -- [ rot[4]  rot[5]  rot[6]  ]
    -- [ rot[8]  rot[9]  rot[10] ]

    local nx = rot[0] * n.x + rot[1] * n.y + rot[2] * n.z
    local ny = rot[4] * n.x + rot[5] * n.y + rot[6] * n.z
    local nz = rot[8] * n.x + rot[9] * n.y + rot[10] * n.z

    if nz > 0 then
      local key = math.abs(nx) + math.abs(ny)
      if key < key_min then
        key_min = key
        face_i = i
      end
    end
  end

  local result = face_i
  for _, bonus in ipairs(this_roll.bonuses) do
    result = result + bonus.value
  end
  return result
end

jit.off(rolling.make)

Ldump.mark(rolling, {}, ...)
return rolling
