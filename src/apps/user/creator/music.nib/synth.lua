function audio_init()
    -- Primeiro canal
    channel(CH1)
    -- Frequências
    freqs(2.01, 0.99, 0.01, 0.01)
    -- Envelopes
    envelope(OP1, 0, 1, 0.005, 0.05, 0.9, 2.0)
    envelope(OP2, 0, 1, 0.005, 0.05, 0.45, 0.1)
    envelope(OP3, 0, 1, 0.005, 0.05, 0.99, 0)
    --envelope(OP4, 0, 1, 0.4, 0.1, 0.9, 1)
    -- Roteia
    route(OP1, OUT, 0.1)
    route(OP1, OP1, 0.5)
    route(OP2, OP1, 2.0)
    route(OP3, OP1, 1.0)
    --route(OP4, OP3, 0.8)
    -- Reverb
    --reverb(4, 0.6)
end

local base = 39-12
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

function audio_tick()
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

    --local notes = {48, 50, 51, 53, 51, 50}

    --local p = 1/8

    --if sync%math.floor(speed) == 0 then
    --    dprint(notes[note]-12)
    --    noteon(notes[note]-12, writep%16)
    --    writep += 1

    --    note += 1

    --    if note > #notes then
    --        note = 1
    --    end
    --end

    --if sync%600 == 0 and speed > 2 then
    --    speed /= 2

    --    envelope(OP3, 0, 1, 0.5/speed, 0.1, 0.3, 1)

    --    for _, note in ipairs(notes) do
    --        note -= 6
    --    end
    --end

    sync += 1
end
