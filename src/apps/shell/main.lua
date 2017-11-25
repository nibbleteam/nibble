local PAL_SIZE = 16
local PAL_ENTRY_SIZE = 4
local PAL_NUM = 8
local GPU_CMD_SIZE = 32

-- Posições na memória
local GPU = 0
local PAL = GPU+GPU_CMD_SIZE
local VID = PAL+PAL_SIZE*PAL_NUM*PAL_ENTRY_SIZE

-- Números de 16 bits
function u16(x)
    return string.char(math.floor(x/256), math.floor(math.floor(x)%256))
end

-- Parâmetros de 16 bits
function gpu3(a, b, c)
    return u16(a)..u16(b)..u16(c)
end

function gpu4(a, b, c, d)
    return u16(a)..u16(b)..u16(c)..u16(d)
end

function gpu6(a, b, c, d, e, f)
    return gpu4(a, b, c, d)..u16(e)..u16(f)
end

function gpu8(a, b, c, d, e, f, g, h)
    return gpu4(a, b, c, d)..gpu4(e, f, g, h)
end

function init()
    math.randomseed(os.time())

    local r
    local g
    local b
    r, g, b = 1, 1, 1
    for i=PAL,PAL+PAL_SIZE*PAL_NUM*PAL_ENTRY_SIZE,4 do
        kernel.write(i, string.char(math.floor(r), math.floor(g), math.floor(b), 0))

        r = (r+math.random()*128-30)%256
        g = (g+math.random()*128-30)%256
        b = (b+math.random()*128-64)%256

        if i%16 == 0 then
            r, g, b = 1, 50, 128
        end
    end
end

local t = 0
local pal = 0
function draw()
    t = t + 0.017

    if math.floor(t*2)%2 ~= 0 and change then
        change = false
        pal = (pal+1)%8
    end

    if math.floor(t*2)%2 == 0 then
        change = true
    end
    
    x, y = 0, 0

    -- Desenha um sprite (vazio)
    -- com uma paleta aleatória
    kernel.write(0, '\10'..string.char(pal)..gpu6(x, y, 0, 0, 320, 240))
end

function update()
end
