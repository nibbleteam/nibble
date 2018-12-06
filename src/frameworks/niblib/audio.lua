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

local ch = 0

local OP1 = 0
local OP2 = 1
local OP3 = 2
local OP4 = 3
local OUT = 4

local CH1 = 0
local CH2 = 1
local CH3 = 2
local CH4 = 3
local CH5 = 5
local CH6 = 6
local CH7 = 7
local CH8 = 8

audio.OP1 = OP1
audio.OP2 = OP2
audio.OP3 = OP3
audio.OP4 = OP4
audio.OUT = OUT

audio.CH1 = CH1
audio.CH2 = CH2
audio.CH3 = CH3
audio.CH4 = CH4
audio.CH5 = CH5
audio.CH6 = CH6
audio.CH7 = CH7
audio.CH8 = CH8

local FREQ_SIZE = 4*2
local CH_SIZE = 256
local ENV_SIZE = 6*2
local ENVS_SIZE = ENV_SIZE*4
local LINE_SIZE = 5*2
local MAT_SIZE = LINE_SIZE*4
local CELL_SIZE = 2

local function encode(n)
    return u16(n*255.0)
end

local function channel(c)
    audio.ch = c
end

local function envelope(op, sustain, volume, a, d, s, r)
    local str = encode(sustain)..encode(volume)
    str = str..encode(a)..encode(d)..encode(s)..encode(r)
    
    kernel.write(154448+ch*CH_SIZE+FREQ_SIZE+op*ENV_SIZE, str)
end

local function freqs(op1, op2, op3, op4)
    local str = encode(op1)..encode(op2)..encode(op3)..encode(op4)

    kernel.write(154448+ch*CH_SIZE, str)
end

local function reverb(delay, feedback)
    local str = string.char(delay)..encode(feedback)

    kernel.write(154448+CH_SIZE*ch+FREQ_SIZE+ENVS_SIZE+MAT_SIZE+16*2, str)
end

local function route(from, to, amplitude)
    kernel.write(154448+CH_SIZE*ch+ENVS_SIZE+FREQ_SIZE+from*LINE_SIZE+to*CELL_SIZE, encode(amplitude))
end

local function noteon(n, i)
    kernel.write(154448+CH_SIZE*ch+FREQ_SIZE+ENVS_SIZE+MAT_SIZE+i*2, '\x01'..string.char(n));
end

local function noteoff(n, i)
    kernel.write(154448+CH_SIZE*ch+FREQ_SIZE+ENVS_SIZE+MAT_SIZE+i*2, '\x02'..string.char(n));
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
