function audio_init()
    -- Primeiro canal
    channel(CH1)
    -- Frequências
    freqs(2.0, 1, 0.01, 0.01)
    -- Envelopes
    envelope(OP1, 0, 1, 0.01, 0.01, 0.6, 0.01)
    envelope(OP2, 0, 1, 0.01, 0.04, 0.45, 0.01)
    envelope(OP3, 0, 1, 0.5, 0.01, 0.99, 0.01)
    envelope(OP4, 0, 1, 0.01, 0.01, 0.9, 0.01)
    -- Roteia
    route(OP1, OUT, 0.1)
    route(OP2, OP1, 2.0)
    route(OP3, OUT, 0.3)
    route(OP4, OP3, 2.0)
    -- Reverb
    --reverb(4, 0.6)
end

local base = 39-12
local octs = 'zsxdcvgbhnjmq2w3er5t6y7ui9o0p'

local writep = 0

local pattern_size = 32

pattern = {}
tick = 0
subtick = 0

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

            dprint(n)
        end
    end

    if pattern[tick] then
        for n=0,12*6-1 do
            if pattern[tick][n] then
                noteon(n, writep%16)
                writep += 1
            end
        end
    end

    subtick += 1

    if subtick%16 == 0 then
        tick = (tick+1)%pattern_size
    end
end
