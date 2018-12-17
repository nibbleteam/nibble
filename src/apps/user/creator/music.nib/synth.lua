function audio_init()
    -- Primeiro canal
    channel(CH1)
    -- Frequências
    freqs(0.9, 0.98, 0.94, 0.93)
    -- Envelopes
    envelope(OP1, 0, 1, 0.5, 0.01, 1, 0.4)
    envelope(OP2, 0, 1, 0.5, 0.01, 0.2, 0.4)
    envelope(OP3, 0, 1, 0.5, 0.01, 0.2, 0.4)
    envelope(OP4, 0, 1, 0.5, 0.01, 0.2, 0.4)
    -- Roteia
    route(OP1, OUT, 0.1)
    route(OP2, OP1, 0.8)
    route(OP3, OP2, 0.2)
    route(OP4, OP3, 0.5)
    -- Reverb
    --reverb(32, 0.6)
end

local base = 39-12
local octs = 'zsxdcvgbhnjmq2w3er5t6y7ui9o0p'

local writep = 0

music_size = 128
tick = 0
subtick = 0

function audio_tick()
    if playing then
        subtick += 1

        if subtick%music_period == 0 then
            if music[tick] then
                for n=0,12*6-1 do
                    if music[tick][n] then
                        noteon(n, writep%16)
                        writep += 1
                    end
                end
            end

            tick = (tick+1)%music_size

            local timeline_position = tick/music_size

            local tick_info = tostring(tick)..'/'..tostring(music_size)
            local current_time = tostring(math.floor(tick*music_period*1/60*10)/10)..'s'

            local header_line = tick_info .. ' | ' .. current_time

            nom:find('#timeline'):update_position(timeline_position)
            nom:find('#header').content = header_line
        end
    end
end

function audio_update(dt)
    local input = kernel.read(81606, 1)

    if input:byte() > 0 then
        local input = kernel.read(81606+1, input:byte())

        for k=1,#input do
            -- Encontra a nota
            local n = octs:find(input:sub(k, k))

            if n ~= nil then
                n += base-1

                -- Toca
                noteon(n, writep%16)
                writep += 1
            end
        end
    end
end
