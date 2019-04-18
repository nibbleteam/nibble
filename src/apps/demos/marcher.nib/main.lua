-- Ray Marcher
-- By: Felipe Tavares, Jan 2, 2019
-- Demo for the Nibble console

local vec = {}

vec.new = function(x, y, z)
    local v = {x, y, z}

    setmetatable(v, vec)

    return v
end

vec.__index = function(self, idx)
    if idx == 'x' then
        return self[1]
    end

    if idx == 'y' then
        return self[2]
    end

    if idx == 'z' then
        return self[3]
    end

    return vec[idx]
end

vec.__add = function(va, vb)
    return vec.new(va.x+vb.x, va.y+vb.y, va.z+vb.z)
end

vec.__sub = function(va, vb)
    return vec.new(va.x-vb.x, va.y-vb.y, va.z-vb.z)
end

vec.__mul = function(va, vb)
    if type(vb) == 'number' then
        return vec.new(va.x*vb, va.y*vb, va.z*vb)
    else
        return vec.new(va.x*vb.x, va.y*vb.y, va.z*vb.z)
    end
end

vec.__len = function(v)
    return math.sqrt(v.x*v.x+v.y*v.y+v.z*v.z)
end

vec.normal = function(v)
    local l = #v

    return vec.new(v.x/l, v.y/l, v.z/l)
end

local res_x = 128
local res_y = 128

-- Fast screen representation
local pixels = {}

-- Camera description
local cam_pos = vec.new(0, 0, 0)
local scr_pos = vec.new(-0.5, -0.5, 0.1)
local scr_size = vec.new(1/res_x, 1/res_y, 0)

-- Test sphere
local sphere_pos = vec.new(0, 0, 1)
local sphere_rad = 1

-- Hit threshold
local ray_threshold = 0.01

function init()
    local colormap = {}

    for i=0,127 do
        colormap[i*4+1] = string.char(math.floor(i*2))
        colormap[i*4+2] = string.char(math.floor(i*2))
        colormap[i*4+3] = string.char(math.floor(i*2))
        colormap[i*4+4] = string.char(255)
    end

    kernel.write(32, table.concat(colormap))

    for i=1,320*240 do
        pixels[i] = string.char(0)
    end
end

function distance_to_scene(p)
    local p_ = vec.new((p.x+0.5)%1.0-0.5, (p.y+0.5)%1.0-0.5, p.z%1.0)
    
    return #(p_-sphere_pos)-sphere_rad
end

function create_ray(x, y)
    local scr_point = vec.new(x, y, 0)*scr_size+scr_pos
    local ray = scr_point-cam_pos

    return ray:normal()
end

function march_ray(ray)
    local p = vec.new(ray.x, ray.y, ray.z)

    for step=1,4 do
        local min_dist = distance_to_scene(p) 

        if min_dist < ray_threshold then
            --return math.min(math.floor(#p*32), 127)
            return 127
        end

        p = p+ray*min_dist
    end

    --return math.min(math.floor(#p*60), 127)
    return 0
end

function color_at(x, y)
    return march_ray(create_ray(x, y))
end

function draw()
    for y=0,res_y-1 do
        for x=0,res_x-1 do
            pixels[y*320+x+1] = string.char(color_at(x, y))
        end
    end

    kernel.write(0x320, table.concat(pixels))
end

local t = 0

function update(dt)
    t += dt

    cam_pos[3] -= dt
end
