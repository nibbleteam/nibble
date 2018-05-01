local audio = {}
local NOTE_TABLE = {
  A= 0,
  As= 1,
  B= 2,
  C= 3,
  Cs= 4,
  D= 5,
  Ds= 6,
  E= 7,
  F= 8,
  Fs= 9,
  G= 10,
  Gs= 11
}

local MEM_BASE = 0x25a4a
local MEM_OFFSET = MEM_BASE+14
local WRITE_POS = MEM_OFFSET

local CMD_LENGTH = 2
local CONF_LENGTH = 2

function u16(x)
  return string.char(math.floor(x/256)%256, math.floor(math.floor(x)%256))
end

function audio.mksnd()
  return WRITE_POS-MEM_BASE
end

function audio.note(n, o)
  n = n:gsub('#', 's')
  local note = '\00'..string.char(NOTE_TABLE[n]+o*16)
  kernel.write(WRITE_POS, note)
  WRITE_POS = WRITE_POS+CMD_LENGTH
end

function audio.skip(n)
  WRITE_POS = WRITE_POS+CMD_LENGTH*n
end

function audio.rep(n)
  local jump = WRITE_POS+4*(n-1)-MEM_BASE

  kernel.write(WRITE_POS, '\02\00'..u16(jump))
  WRITE_POS = WRITE_POS+4
end

function audio.loop(n)
  local jump = WRITE_POS+4*(n-1)-MEM_BASE

  kernel.write(WRITE_POS, '\04\00'..u16(jump))
  WRITE_POS = WRITE_POS+4
end

function audio.stop()
  kernel.write(WRITE_POS, '\03')
  WRITE_POS = WRITE_POS+4
end

function audio.snd(p, c)
  c = c or 0

  kernel.write(MEM_BASE+c*CONF_LENGTH, u16(p))
end

function audio.adsr(c, a, d, s, r)
  c = c or 0
  a = a or 0
  d = d or 0
  s = s or 0
  r = r or 0

  kernel.write(MEM_BASE+c*8+5, string.char(a))
  kernel.write(MEM_BASE+c*8+6, string.char(s))
  kernel.write(MEM_BASE+c*8+7, string.char(r))
end

function audio_tick(channel)
    kernel.write(MEM_BASE+4*channel, "\00\00\00\00")
end

return audio
