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

local FREQ_SIZE = 4*2
local CH_SIZE = 256
local ENV_SIZE = 6*2
local ENVS_SIZE = ENV_SIZE*4
local LINE_SIZE = 5*2
local MAT_SIZE = LINE_SIZE*4
local CELL_SIZE = 2

function encode(n)
    return u16(n*255.0)
end

function channel(c)
    ch = c
end

function envelope(op, sustain, volume, a, d, s, r)
    local str = encode(sustain)..encode(volume)
    str = str..encode(a)..encode(d)..encode(s)..encode(r)
    
    kernel.write(154448+ch*CH_SIZE+FREQ_SIZE+op*ENV_SIZE, str)
end

function freqs(op1, op2, op3, op4)
    local str = encode(op1)..encode(op2)..encode(op3)..encode(op4)

    kernel.write(154448+ch*CH_SIZE, str)
end

function reverb(delay, feedback)
    local str = string.char(delay)..encode(feedback)

    kernel.write(154448+CH_SIZE*ch+FREQ_SIZE+ENVS_SIZE+MAT_SIZE+16*2, str)
end

function route(from, to, amplitude)
    kernel.write(154448+CH_SIZE*ch+ENVS_SIZE+FREQ_SIZE+from*LINE_SIZE+to*CELL_SIZE, encode(amplitude))
end

function noteon(n, i)
    kernel.write(154448+CH_SIZE*ch+FREQ_SIZE+ENVS_SIZE+MAT_SIZE+i*2, '\x01'..string.char(n));
end

function noteoff(n, i)
    kernel.write(154448+CH_SIZE*ch+FREQ_SIZE+ENVS_SIZE+MAT_SIZE+i*2, '\x02'..string.char(n));
end

function audio_init()
    -- Primeiro canal
    channel(CH1)
    -- Frequências
    freqs(18, 1, 1, 0.01)
    -- Envelopes
    envelope(OP1, 0, 1, 0.005, 0.05, 0.9, 0.01)
    envelope(OP2, 0, 1, 0.005, 0.05, 0.9, 0.01)
    envelope(OP3, 0, 1, 0.01, 0.1, 0.3, 1)
    envelope(OP4, 0, 1, 0.01, 0.1, 0.9, 1)
    -- Roteia
    route(OP1, OUT, 0.1)
    route(OP2, OP1, 0.2)
    route(OP3, OUT, 0.5)
    route(OP4, OP3, 0.8)
    -- Reverb
    --reverb(8, 0.8)
end

local base = 39
local octs = 'zsxdcvgbhnjmq2w3er5t6y7ui9o0p'

local spent = 0
local note = 1
local writep = 0

fm = {
    0, 0, 0, 0,
    0, 0, 0, 0
}

local sync = 0
local speed = 64

function audio_tick(dt)
    local input = kernel.read(154410, 16)

    for k=1,#input do
        -- Encontra a nota
        local n = octs:find(input:sub(k, k))

        if n ~= nil then
            n += base-1

            -- Toca
            channel(CH1)
            noteon(n, writep%16)
            writep += 1
        end
    end

    local notes = {48, 50, 51, 53, 51, 50}

    local p = 1/8

    if sync%math.floor(speed) == 0 then
        dprint(notes[note]-12)
        noteon(notes[note]-12, writep%16)
        writep += 1

        note += 1

        if note > #notes then
            note = 1
        end
    end

    if sync%600 == 0 and speed > 2 then
        speed /= 2
    end

    sync += 1
end
