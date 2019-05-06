local hw = require('frameworks.kernel.hw')
local audio = {}

local audio_addr = 77568

local ch = 0

audio.OP1 = 0
audio.OP2 = 1
audio.OP3 = 2
audio.OP4 = 3
audio.OUT = 4

audio.CH1 = 0
audio.CH2 = 1
audio.CH3 = 2
audio.CH4 = 3
audio.CH5 = 5
audio.CH6 = 6
audio.CH7 = 7
audio.CH8 = 8

local FREQ_SIZE = 4*2
local CH_SIZE = 152
local ENV_SIZE = 6*2
local ENVS_SIZE = ENV_SIZE*4
local LINE_SIZE = 5*2
local MAT_SIZE = LINE_SIZE*4
local CELL_SIZE = 2
local TYPES_SIZE = 4

local function u16(x)
  local signal = x
  x = math.abs(x)

  if signal < 0 then
    signal = 128
  else
    signal = 0
  end

  return string.char(math.floor(x/256)%128+signal, math.floor(x)%256)
end

local function encode(n)
    return u16(n*255.0)
end

local function channel(c)
    ch = c or 0
end

local function envelope(op, sustain, volume, a, d, s, r, wave)
    local str = encode(sustain)..encode(volume)
    str = str..encode(a)..encode(d)..encode(s)..encode(r)
    
    hw.write(audio_addr+ch*CH_SIZE+FREQ_SIZE+op*ENV_SIZE, str)
    hw.write(audio_addr+ch*CH_SIZE+FREQ_SIZE+op*ENV_SIZE+MAT_SIZE+16*3+op, string.char(wave))
end

local function freqs(op1, op2, op3, op4)
    local str = encode(op1)..encode(op2)..encode(op3)..encode(op4)

    hw.write(audio_addr+ch*CH_SIZE, str)
end

local function reverb(delay, feedback)
    local str = string.char(delay)..'\00'..encode(feedback)

    hw.write(audio_addr+CH_SIZE*ch+FREQ_SIZE+ENVS_SIZE+MAT_SIZE+4+16*3, str)
end

local function route(from, to, amplitude)
    hw.write(audio_addr+CH_SIZE*ch+ENVS_SIZE+FREQ_SIZE+from*LINE_SIZE+to*CELL_SIZE, encode(amplitude))
end

local function noteon(n, i, intensity)
    hw.write(audio_addr+CH_SIZE*ch+FREQ_SIZE+ENVS_SIZE+MAT_SIZE+TYPES_SIZE+i*3, '\x01'..string.char(n)..string.char(intensity or 0));
end

local function noteoff(n, i)
    hw.write(audio_addr+CH_SIZE*ch+FREQ_SIZE+ENVS_SIZE+MAT_SIZE+TYPES_SIZE+i*3, '\x02'..string.char(n));
end

audio.encode = encode
audio.channel = channel
audio.envelope = envelope
audio.freqs = freqs
audio.reverb = reverb
audio.route = route
audio.noteon = noteon
audio.noteoff = noteoff

return audio
