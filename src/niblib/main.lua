-- Niblib
-- Biblioteca de API utilitária para o Nibble
-- https://github.com/pongboy/nibble

-- Constantes
-- Áreas de memória
local NIBLIB_GPU_CMD = 0x00
-- Tamanhos
local NIBLIB_PAL_NUM = 0x08

local NIBLIB_SPR_W = 0x10
local NIBLIB_SPR_H = 0x10
local NIBLIB_SPRSHEET_W = 0x2000
local NIBLIB_SPRSHEET_H = 0x0400
-- Comandos
local NIBLIB_GPU_SPRITE = string.char(0x0a)

-- Funções genéricas para GPU
-- Números de 16 bits
function u16(x)
    return string.char(math.floor(x/256)%256, math.floor(math.floor(x)%256))
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

-- Define API
function spr(x, y, sprx, spry, pal)
    -- Paleta padrão
    pal = pal or 0
    -- Garante que todos são inteiros e a paleta é entre 0-7
    x, y = math.floor(x), math.floor(y)
    sprx, spry = math.floor(sprx), math.floor(spry)
    pal = math.floor(pal)%NIBLIB_PAL_NUM
    -- Sprites para pixels
    sprx, spry = sprx*NIBLIB_SPR_W, spry*NIBLIB_SPR_H
    -- Envia o comando para a GPU
    kernel.write(NIBLIB_GPU_CMD,
                 NIBLIB_GPU_SPRITE..
                 string.char(pal)..
                 gpu6(sprx, spry, x, y, NIBLIB_SPR_W, NIBLIB_SPR_H))
end

-- Apaga variáveis globais desnecessárias
os = nil
--print = nil
