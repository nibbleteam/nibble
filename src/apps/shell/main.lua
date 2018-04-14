function init()
  -- Deixa a cor 0 na paleta 0 transparente
  kernel.write(0x20+3, '\0')

  mus = mksnd()
  note('C', 2)
  rep(-1)
  note('E', 2)
  skip(3)
  note('A', 2)
  skip(3)
  note('C', 2)
  skip(1)
  note('D', 2)
  skip(5)
  loop(-18)

  bump = mksnd()
  note('A', 4)
  stop()

  -- Toca no canal 1, temos 2 canais
  snd(mus, 1)

  --adsr(0, 0, 0, 0, 0)
  --adsr(1, 128, 0, 0, 2)
end

local x, y = 0, 0
local v, w = 2, 4
local btstr = ""
local kbd = ""
function draw()
  clr()

  -- Nibble logo
  -- Caracteres especiais são numerados na ordem
  -- que aparecem na spritesheet
  print("\12", x, y)

  print("pos "..tostring(x)..", "..tostring(y), 0, 0)
  print(kbd, 0, 8)
  print(tostring(time()), 0, 16)

  print(btstr, 0, 232)
end

function update()
  local keys = kernel.read(0x25A2a, 1)

  if #keys > 0 then
    -- Backspace
    if keys == "\8" then
      if #kbd > 0 then
        kbd = kbd:sub(1, #kbd-1)
      end
    -- Enter
    elseif keys == "\13" then
      kbd = ""
    else
      kbd = kbd..keys
    end
  end

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

  x, y = x+v, y+w

  if x <= 0 or x >= 319-8 then
    v = v*-1
    snd(bump)
  end

  if y <= 0 or y >= 239-8 then
    w = w*-1
    snd(bump)
  end
end
