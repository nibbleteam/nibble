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

function audio_tick()
    for channel=0,8 do
        kernel.write(MEM_BASE+4*channel, "\00\00\00\00")
    end
end

-- TODO
function audio_tmp()
    if t%30 == 0 then
        -- Frequencies
        kernel.write(154448, '\xff\x80')
        -- No sustain + envelopes
        kernel.write(154448+4, '\x00\xc0\x01\x01\x60\x01')
        kernel.write(154448+10, '\x00\xc0\x01\x01\x60\x01')
        -- Routing table
        kernel.write(154448+4+4*6+0*5+1, string.char(60))
        kernel.write(154448+4+4*6+1*5+4, string.char(255))

        -- A4, note on
        kernel.write(154448+48, '\x01\x30');
    end

    if t%p0 == 0 and t > 60 then
        -- Frequencies
        kernel.write(154448+64, '\x80'..string.char(c0a0))
        -- No sustain + envelopes
        kernel.write(154448+4+64, '\x00\xff\x80\x01\x80\x01')
        kernel.write(154448+10+64, '\x00\xff\x40\x01\x80\x01')
        -- Routing table
        kernel.write(154448+4+4*6+0*5+1+64, string.char(60))
        kernel.write(154448+4+4*6+1*5+4+64, string.char(255))

        local p = math.floor(t/p0)%#c0+1

        -- note on
        kernel.write(154448+64+48, '\x01'..string.char(c0[p]));

        if p == #c0 then
            for i=1,#c0 do
                if c0[i] >= 48 then
                    c0[i] = c0[i]-12
                end

                if c0a0 > 128 then
                    c0a0 = 128
                    p0 = 30
                end
            end
        end
    end

    if t%p1 == 0 and t > 120 then
        -- Frequencies
        kernel.write(154448+2*64, '\x80'..string.char(c1a0))
        -- No sustain + envelopes
        kernel.write(154448+4+2*64, '\x00\xff\x25\x50\x80\x10')
        kernel.write(154448+10+2*64, '\x00\xff\x05\x20\xb0\x01')
        -- Routing table
        kernel.write(154448+4+4*6+0*5+1+2*64, string.char(60))
        kernel.write(154448+4+4*6+1*5+4+2*64, string.char(255))

        local p = math.floor(t/p1)%#c1+1

        -- note on
        kernel.write(154448+2*64+48, '\x01'..string.char(c1[p]));
    end

    t += 1
end

return audio
