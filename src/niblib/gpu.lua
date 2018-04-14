local gpu = {}

-- Envio de comandos para GPU nesse addr
local GPU_CMD = 0x00

local PAL_NUM = 0x08

local SPR_W = 0x10
local SPR_H = 0x10
local SPRSHEET_W = 0x2000
local SPRSHEET_H = 0x0400

local DEFAULT_PAL = 0
local DEFAULT_COLOR = 0

local DEFAULT_FT_W = 10
local DEFAULT_FT_H = 10
local DEFAULT_CH_W = 8
local DEFAULT_CH_H = 8
local DEFAULT_FT_CHARS = "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ.,!?abcdefghijklmnopqrstuvwxyz()[]<>{}\"\"'-_=\\/|&~*%@$#:;+"..string.char(1)..string.char(2)..string.char(3)..string.char(4)..string.char(5)..string.char(6)..string.char(7)..string.char(8)..string.char(9)..string.char(10)..string.char(11)..string.char(12)..string.char(13).." "

-- Comandos
local GPU_CLEAR = string.char(0x00)
local GPU_RECTFILL = string.char(0x01)
local GPU_QUADFILL = string.char(0x02)
local GPU_TRIFILL = string.char(0x03)
local GPU_CIRCFILL = string.char(0x04)
local GPU_LINE = string.char(0x05)
local GPU_RECT = string.char(0x06)
local GPU_QUAD = string.char(0x07)
local GPU_TRI = string.char(0x08)
local GPU_CIRC = string.char(0x09)
local GPU_SPRITE = string.char(0x0a)

function round(x)
  return math.floor(x)

  --if x >= math.floor(x)+0.5 then
  --  return math.ceil(x)
  --else
  --  return math.floor(x)
  --end
end

-- Funções para enviar argumentos
-- Big Endian de 16 bits para a GPU
function u16(x)
  local signal = x
  x = math.abs(x)

  if signal < 0 then
    signal = 128
  else
    signal = 0
  end

  return string.char(round(x/256)%128+signal, round(x)%256)
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

-- Primitivas
function gpu.clr(color)
  color = color or DEFAULT_COLOR

  color = math.floor(color)%128

  kernel.write(GPU_CMD,
               GPU_CLEAR..
                 string.char(color))
end

-- Sprite
function gpu.spr(x, y, sprx, spry, pal)
  assert(x, "spr() needs a x value")
  assert(y, "spr() needs a y value")
  assert(sprx, "spr() needs a sprx value")
  assert(spry, "spr() needs a spry value")

  -- Paleta padrão
  pal = pal or DEFAULT_PAL 
  -- Garante que todos são inteiros e a paleta é entre 0-7
  x, y = math.floor(x), math.floor(y)
  sprx, spry = math.floor(sprx), math.floor(spry)
  pal = math.floor(pal)%PAL_NUM
  -- Sprites para pixels
  sprx, spry = sprx*SPR_W, spry*SPR_H
  -- Envia o comando para a GPU
  kernel.write(GPU_CMD,
               GPU_SPRITE..
                 string.char(pal)..
                 gpu6(sprx, spry, x, y, SPR_W, SPR_H))
end

-- Pixel sprite
function gpu.pspr(x, y, sx, sy, w, h, pal)
  assert(x, "pspr() needs a x value")
  assert(y, "pspr() needs a y value")
  assert(sx, "pspr() needs a sx value")
  assert(sy, "pspr() needs a sy value")
  assert(w, "pspr() needs a w value")
  assert(h, "pspr() needs a h value")

  pal = pal or DEFAULT_PAL
  x, y = math.floor(x), math.floor(y)
  sx, sy = math.floor(sx), math.floor(sy)
  pal = math.floor(pal)%PAL_NUM

  kernel.write(GPU_CMD,
               GPU_SPRITE..
                 string.char(pal)..
                 gpu6(sx, sy, x, y, w, h))
end

-- Paleta
function gpu.pal(pal)
  assert(pal, "pal() needs a pal value")

  DEFAULT_PAL = math.floor(pal)%PAL_NUM
end

-- Cor
function gpu.col(color)
  assert(color, "col() needs a color value")

  DEFAULT_COLOR = math.floor(color)%128
end

-- Mistura cor e paleta
function gpu.mix(color, pal)
  assert(color, "mix() needs a color value")
  assert(color, "mix() needs a pal value")

  return 16*(math.floor(pal)%PAL_NUM)+math.floor(color)%16
end

-- Rectfill
function gpu.rectf(x, y, w, h, color)
  assert(x, "rectf() needs a x value")
  assert(y, "rectf() needs a y value")
  assert(w, "rectf() needs a w value")
  assert(h, "rectf() needs a h value")

  color = color or DEFAULT_COLOR

  kernel.write(GPU_CMD,
               GPU_RECTFILL..
                 string.char(color)..
                 gpu4(x, y, w, h))
end

-- Quadfill 
function gpu.quadf(x1, y1, x2, y2, x3, y3, x4, y4, color)
  assert(x1, "quadf() needs a x1 value")
  assert(y1, "quadf() needs a y1 value")
  assert(x2, "quadf() needs a x2 value")
  assert(y2, "quadf() needs a y2 value")
  assert(x3, "quadf() needs a x3 value")
  assert(y3, "quadf() needs a y3 value")
  assert(x4, "quadf() needs a x4 value")
  assert(y4, "quadf() needs a y4 value")

  color = color or DEFAULT_COLOR

  kernel.write(GPU_CMD,
               GPU_QUADFILL..
                 string.char(color)..
                 gpu8(x1, y1, x2, y2,
                      x3, y3, x4, y4))
end

-- Trifill 
function gpu.trif(x1, y1, x2, y2, x3, y3, color)
  assert(x1, "trif() needs a x1 value")
  assert(y1, "trif() needs a y1 value")
  assert(x2, "trif() needs a x2 value")
  assert(y2, "trif() needs a y2 value")
  assert(x3, "trif() needs a x3 value")
  assert(y3, "trif() needs a y3 value")

  color = color or DEFAULT_COLOR

  kernel.write(GPU_CMD,
               GPU_TRIFILL..
                 string.char(color)..
                 gpu6(x1, y1, x2, y2, x3, y3))
end

-- Circlefill 
function gpu.circf(x1, y1, r, color)
  assert(x1, "circf() needs a x1 value")
  assert(y1, "circf() needs a y1 value")
  assert(r, "circf() needs a r value")

  color = color or DEFAULT_COLOR

  kernel.write(GPU_CMD,
               GPU_CIRCFILL..
                 string.char(color)..
                 gpu3(x1, y1, r))
end

-- Line 
function gpu.line(x1, y1, x2, y2, color)
  assert(x1, "line() needs a x1 value")
  assert(y1, "line() needs a y1 value")
  assert(x2, "line() needs a x2 value")
  assert(y2, "line() needs a y2 value")

  color = color or DEFAULT_COLOR

  kernel.write(GPU_CMD,
               GPU_LINE..
                 string.char(color)..
                 gpu4(x1, y1, x2, y2))
end

-- Rect
function gpu.rect(x, y, w, h, color)
  assert(x, "rect() needs a x value")
  assert(y, "rect() needs a y value")
  assert(w, "rect() needs a w value")
  assert(h, "rect() needs a h value")

  color = color or DEFAULT_COLOR

  kernel.write(GPU_CMD,
               GPU_RECT..
                 string.char(color)..
                 gpu4(x, y, w, h))
end

-- Quad
function gpu.quad(x1, y1, x2, y2, x3, y3, x4, y4, color)
  assert(x1, "quad() needs a x1 value")
  assert(y1, "quad() needs a y1 value")
  assert(x2, "quad() needs a x2 value")
  assert(y2, "quad() needs a y2 value")
  assert(x3, "quad() needs a x3 value")
  assert(y3, "quad() needs a y3 value")
  assert(x4, "quad() needs a x4 value")
  assert(y4, "quad() needs a y4 value")

  color = color or DEFAULT_COLOR

  kernel.write(GPU_CMD,
               GPU_QUAD..
                 string.char(color)..
                 gpu8(x1, y1, x2, y2,
                      x3, y3, x4, y4))
end

-- Tri
function gpu.tri(x1, y1, x2, y2, x3, y3, color)
  assert(x1, "tri() needs a x1 value")
  assert(y1, "tri() needs a y1 value")
  assert(x2, "tri() needs a x2 value")
  assert(y2, "tri() needs a y2 value")
  assert(x3, "tri() needs a x3 value")
  assert(y3, "tri() needs a y3 value")

  color = color or DEFAULT_COLOR

  kernel.write(GPU_CMD,
               GPU_TRI..
                 string.char(color)..
                 gpu6(x1, y1, x2, y2, x3, y3))
end

-- Circle
function gpu.circ(x1, y1, r, color)
  assert(x1, "circ() needs a x1 value")
  assert(y1, "circ() needs a y1 value")
  assert(r, "circ() needs a r value")

  color = color or DEFAULT_COLOR

  kernel.write(GPU_CMD,
               GPU_CIRC..
                 string.char(color)..
                 gpu3(x1, y1, r))
end

-- Printstring
function gpu.print(str, dstx, dsty, pal)
  assert(str, "print() needs a str value")
  assert(dstx, "print() needs a x value")
  assert(dsty, "print() needs a y value")

  for i=1,#str do
    local ch = str:sub(i, i)
    local index, _ = DEFAULT_FT_CHARS:find(ch, 1, true)

    if index ~= nil then
      local px = math.floor((index-1)%DEFAULT_FT_W)*DEFAULT_CH_W
      local py = math.floor((index-1)/DEFAULT_FT_W)*DEFAULT_CH_H

      gpu.pspr(dstx, dsty, px, py, DEFAULT_CH_W, DEFAULT_CH_H)
    end

    dstx = dstx+DEFAULT_CH_W
  end
end

return gpu
