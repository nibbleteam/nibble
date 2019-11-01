-- Voxlle
-- A Simple .vox file viewer for Nibble

-- local write_line = require 'tty.write_line'

local vox = nil

function init()
  --write_line("Voxlle!")

  if #env.params > 1 then
    display_file(env.params[2])
  else
    --write_line("Please use:")
    --write_line("voxlle <file>")
  end
end

function draw()
  clear(16)

  if vox then
    display_vox(vox)
  end
end

function display_vox(vox)
  local model = vox.models[vox.active]

  local a_x = (clock()/1)%(2*math.pi)
  local a_y = (clock()/2)%(2*math.pi)
  local a_z = (clock()/3)%(2*math.pi)

  local cam = mul_mat(mul_mat(rot_x(a_x), rot_y(a_y)), rot_z(a_z))

  -- Sort voxels by distance
  sort(model.voxels, function(a, b)
    local size = 40
    local ra = mul(cam, { (a[1]-model.size[1]/2)/size, (a[2]-model.size[2]/2)/size, (a[3]-model.size[3]/2)/size, 1 })
    local rb = mul(cam, { (b[1]-model.size[1]/2)/size, (b[2]-model.size[2]/2)/size, (b[3]-model.size[3]/2)/size, 1 })

    ra[3] += 1
    rb[3] += 1

    local da = ra[1]*ra[1]+ra[2]*ra[2]+ra[3]*ra[3]
    local db = rb[1]*rb[1]+rb[2]*rb[2]+rb[3]*rb[3]

    return da < db
  end)

  for _, v in ipairs(model.voxels) do
    local size = 40
    local rotated = mul(cam, { (v[1]-model.size[1]/2)/size, (v[2]-model.size[2]/2)/size, (v[3]-model.size[3]/2)/size, 1 })

    rotated[3] += 1

    if rotated[3] > 0 then
      local p = perspective(rotated)

      fill_circ(p[1], p[2], 2, v[4])
    end
  end

  print("VOX version "..tostring(vox.version), 0, 0)
  print("VOX has "..tostring(#vox.models).." models", 0, 10)
  print("MODEL #"..tostring(vox.active), 0, 20)
  print("MODEL has "..tostring(#model.voxels).." voxels", 0, 30)
end

function update(dt)
  if vox then
    if button_press(RIGHT) then
      vox.active += 1
    end

    if button_press(LEFT) then
      vox.active -= 1
    end
  end
end

function display_file(file_name)
  local file = io.open(file_name)

  if file then
    vox = read_vox(file)
  else
    write_line("The file doesn't exist!")
  end
end

function read_vox(file)
  -- First thing is a "magic" string
  -- It shall contain 'VOX '
  local magic = file:read(4)

  if magic ~= "VOX " then
    write_line("The file is not a .vox :(")

    return
  end

  -- Next we have a verssion number (lil endian)
  local version = toint32(file:read(4))

  -- Now, there are such things as "chunks"
  local _, vox = read_vox_chunk(file)

  vox.version = version

  return vox
end

function read_vox_chunk(file, vox)
  vox = vox or {
    active = 1,
    models = {}
  }

  -- First there is an ID
  local id = file:read(4)

  if not id then
    return 0
  end

  -- write_line("CHUNK. ID: "..id)

  local chunk_size = toint32(file:read(4))

  -- write_line("CHUNK. "..tostring(chunk_size).."bytes long")

  local children_size = toint32(file:read(4))

  -- write_line("CHUNK. CHILDREN. are "..tostring(children_size).." bytes long")

  -- Read the chunk contents
  if chunk_size > 0 then
    if id == "SIZE" then
      read_size_chunk(chunk_size, file, vox)
    elseif id == "XYZI" then
      read_xyzi_chunk(chunk_size, file, vox)
    --elseif id == "RGBA" then
    --  read_rgba_chunk(chunk_size, file, vox)
    else
      -- Skip
      file:read(chunk_size)
    end
  end

  -- Read children
  while children_size > 0 do
    local size = read_vox_chunk(file, vox)
    children_size -= size

    if size == 0 then
        break
    end
  end

  -- Return the chunk size
  return chunk_size + children_size + 4*3, vox
end

function read_size_chunk(chunk_size, file, vox)
  if chunk_size ~= 12 then
    write_line("WRONG CHUNK D:")
    return
  end

  local x, y, z =
    toint32(file:read(4)),
    toint32(file:read(4)),
    toint32(file:read(4))

  --write_line("VOX is sized ("..tostring(x)..", "..tostring(y)..", "..tostring(z)..")")

  insert(vox.models, {
    size = { x, y, z }
  })
end

function read_xyzi_chunk(chunk_size, file, vox)
  local count = toint32(file:read(4))

  --write_line("VOX has "..tostring(count).." voxels")

  local voxels = {}
  for j=1,count do
    local x, y, z, i =
      file:read(1):byte(),
      file:read(1):byte(),
      file:read(1):byte(),
      file:read(1):byte()

    voxels[j] = { x, y, z, i }
  end

  vox.models[#vox.models].voxels = voxels
end

function read_rgba_chunk(chunk_size, file, vox)
end

function toint32(string)
  local bytes = {string:byte(1, #string)}
  local int32 = 0

  for i, byte in ipairs(bytes) do
    int32 += byte*math.pow(256, i-1)
  end

  return int32
end
function dot(a, b)
    return a[1]*b[1]+a[2]*b[2]+a[3]*b[3]+a[4]*b[4]
end

function dot3(a, b)
    return a[1]*b[1]+a[2]*b[2]+a[3]*b[3]
end

function sub(a, b)
    return { a[1]-b[1], a[2]-b[2], a[3]-b[3] }
end

function cross(a, b)
    return { a[2]*b[3] - a[3]*b[2],
             a[3]*b[1] - a[1]*b[3],
             a[1]*b[2] - a[2]*b[1] }
end

function normalize(v)
    local l = math.sqrt(v[1]*v[1]+v[2]*v[2]+v[3]*v[3])

    return { v[1]/l, v[2]/l, v[3]/l }
end

function mul(mat, vec)
    return {
        dot(vec, mat[1]),
        dot(vec, mat[2]),
        dot(vec, mat[3]),
        dot(vec, mat[4])
    }
end

function mul_mat(a, b)
    return {
        mul(b, a[1]),
        mul(b, a[2]),
        mul(b, a[3]),
        mul(b, a[4])
    }
end

function perspective(vec)
    local near = 1
    local d = near/vec[3]

    return {200+120*vec[1]/d, 120+120*vec[2]/d}
end

function rot_x(angle)
    local a = math.cos(angle)
    local b = -math.sin(angle)
    local c = math.sin(angle)

    return {
        {1, 0, 0, 0},
        {0, a, b, 0},
        {0, c, a, 0},
        {0, 0, 0, 1}
    }
end

function rot_y(angle)
    local a = math.cos(angle)
    local b = -math.sin(angle)
    local c = math.sin(angle)

    return {
        {a, 0, c, 0},
        {0, 1, 0, 0},
        {b, 0, a, 0},
        {0, 0, 0, 1}
    }
end

function rot_z(angle)
    local a = math.cos(angle)
    local b = -math.sin(angle)
    local c = math.sin(angle)

    return {
        {a, b, 0, 0},
        {c, a, 0, 0},
        {0, 0, 1, 0},
        {0, 0, 0, 1}
    }
end

function identity()
    return {
        {1, 0, 0, 0},
        {0, 1, 0, 0},
        {0, 0, 1, 0},
        {0, 0, 0, 1}
    }
end
