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

    -- 0 = transparente
    kernel.write(PAL, string.char(0, 0, 0, 0))
end

local t = 0
local pal = 0
local x = 0
local y = 0
function draw()
    t = t + 0.034

    if math.floor(t*6)%2 ~= 0 and change then
        change = false
        pal = (pal+1)%8
        x = x+8

        if x >= 80 then
            x = 0
            y = y+8
        end
    end

    if math.floor(t*6)%2 == 0 then
        change = true
    end
    
    kernel.write(0, '\00\00')
    --kernel.write(0, '\03\03'..gpu6(0, 0, 320, 0, 160, 240))

    -- Desenha um sprite (vazio)
    -- com uma paleta aleatória
    kernel.write(0, '\10\00'..gpu6(x, y, x, y, 8, 8))

end

function update()
end
