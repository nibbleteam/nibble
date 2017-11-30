function init()
  -- Deixa a cor 0 na paleta 0 transparente
  kernel.write(0x20+3, '\0')
end

local x, y = 0, 0
local v, w = 2, 4
local btstr = ""
function draw()
  clr()

  -- Nibble logo
  -- Caracteres especiais são numerados na ordem
  -- que aparecem na spritesheet
  print("\12", x, y)

  print("pos "..tostring(x)..", "..tostring(y), 0, 0)

  print(btstr, 0, 232)
end

function update()
  btstr = ""

  if btd(UP) then
    btstr = btstr.." \1"
    y=y-1
  end

  if btd(RIGHT) then
    btstr = btstr.." \4"
    x=x+1
  end

  if btd(DOWN) then
    btstr = btstr.." \3"
    y=y+1
  end

  if btd(LEFT) then
    btstr = btstr.." \2"
    x=x-1
  end

  if btd(RED) then
    btstr = btstr.." \8"
  end

  if btd(BLUE) then
    btstr = btstr.." \9"
  end
 
  if btd(WHITE) then
    btstr = btstr.." \10"
  end

  if btd(BLACK) then
    btstr = btstr.." \11"
  end

  --x, y = x+v, y+w

  if x <= 0 or x >= 319-8 then
    v = v*-1
  end

  if y <= 0 or y >= 239-8 then
    w = w*-1
  end
end
