local x, y = 0, 0
local wave_type = 0
local volume = 0
local note = 0

function audio_tick(channel)
    if channel == 6 then
        return
    end

    local wave = string.char(wave_type%255)
    local mem = string.char(math.abs(volume)%255).."\03"

    kernel.write(154186+channel*4, wave..mem..string.char(math.abs(note)%12))
end

function init()
  -- Deixa a cor 0 na paleta 0 transparente
  kernel.write(0x20+3, '\0')
end

local v, w = 2, 4
local btstr = ""
local kbd = ""
function draw()
  clr(wave_type%5)


  rectf(100, 100, note%12*10, 10, 8)
  rectf(100, 120, volume, 10, 9)

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

    if btp(RED) then
        wave_type = wave_type+1
    end

    if btd(DOWN) then
        volume = volume - 1
    end

    if btd(UP) then
        volume = volume + 1
    end

    if btp(RIGHT) then
        note = note + 1
    end

    if btp(LEFT) then
        note = note -1
    end

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

  if btd(BLUE) then
    btstr = btstr.." \8"
  end

  if btd(RED) then
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
  end

  if y <= 0 or y >= 239-8 then
    w = w*-1
  end
end
