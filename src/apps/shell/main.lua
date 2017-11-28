function init()
  -- Deixa a cor 0 na paleta 0 transparente
  kernel.write(0x20+3, '\0')

  -- Copia a primeira paleta para as outras
  for i=1,7 do
    kernel.write(i*16*4+32, kernel.read(32, 16*4))
  end
end

local x, y = 0, 0
local v, w = 1, 1
function draw()
  kernel.write(0x220, kernel.read(0x12E20, 320*240))
  spr(x, y, 0, 0)
end

function update()
  local controllers = kernel.read(0x25A21, 1):byte()

  if math.floor(controllers/64) == 2 then
    v, w = 0, -1
  end

  if math.floor(controllers/16)-math.floor(controllers/64)*64 == 2 then
    v, w = 1, 0
  end

  if math.floor(controllers/4)-math.floor(controllers/16)*16 == 2 then
    v, w = 0, 1
  end

  if controllers-math.floor(controllers/4)*4 == 2 then
    v, w = -1, 0
  end

  x, y = x+v, y+w

  if x == 0 or x == 319-16 then
    v = v*-1
  end

  if y == 0 or y == 239-16 then
    w = w*-1
  end
end
