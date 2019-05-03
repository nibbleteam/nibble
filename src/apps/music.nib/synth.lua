variance = math.random()

function keeprandom()
    if math.random() < variance then
        keep = math.random()
    end

    return keep or 0
end

function audio_init()
    math.randomseed(clock())

    -- Primeiro canal
    channel(CH2)
    -- Frequências
    freqs(1.0, 1/math.random(1, 8), keeprandom(), 0.0)
    -- Envelopes
    envelope(OP1, 0, 1, 0.9, 0.0, keeprandom(), keeprandom(), 0)
    envelope(OP2, 0, 1, 0.5, 0.0, keeprandom(), keeprandom(), 0)
    envelope(OP3, 0, 1, 0.9, 0.0, keeprandom(), keeprandom(), 3)
    envelope(OP4, 0, 1, 0.9, 0.01, 0.8, 0.2, 3)
    -- Roteia
    route(OP1, OUT, keeprandom())
    route(OP2, OUT, keeprandom())
    route(OP3, OUT, keeprandom())
    --route(OP1, OP1, keeprandom())
    route(OP2, OP1, keeprandom())
    --route(OP3, OP1, keeprandom())
    --route(OP1, OP2, keeprandom())
    --route(OP2, OP2, keeprandom())
    route(OP3, OP2, keeprandom())
    --route(OP1, OP3, keeprandom())
    --route(OP2, OP3, keeprandom())
    --route(OP3, OP3, keeprandom())
    -- Reverb
    --reverb(8, 0.5)
    channel(CH1)
    -- Frequências
    freqs(1.0, 1.0, 1.0, 2.0)
    -- Envelopes
    envelope(OP1, 0, 1, 0.9, 0.01, 0.3, 0.2, 0)
    envelope(OP2, 0, 1, 0.5, 0.01, 0.3, 0.2, 0)
    envelope(OP3, 0, 1, 0.9, 0.01, 0.3, 0.2, 0)
    envelope(OP4, 0, 1, 0.9, 0.01, 0.3, 0.2, 0)
    -- Roteia
    route(OP1, OUT, 0.05)
    route(OP2, OP1, 2.0)
    route(OP3, OP1, 0.01)
    route(OP4, OP1, 0.01)
end

local base = 39-12
local octs = 'zsxdcvgbhnjmq2w3er5t6y7ui9o0p'

local writep = 0

music_size = 16
tick = 0
subtick = 0

function audio_tick()
    if not RUNNING then
        return
    end

    if playing then
        subtick += 1

        if subtick%music_period == 0 then
            if music[tick] then
                for n=0,12*6-1 do
                    if music[tick][n] then
                        channel(CH2)
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
    local input = read_keys()

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

    local midi_messages = read_midi()

    for _, msg in ipairs(midi_messages) do
        if math.floor((msg[1])/16) == 9 then
            channel(CH2)
            noteon(msg[2], writep%16)
            writep += 1
        elseif math.floor(msg[1]/16) == 11 then
            if msg[2] == 73 then
                channel(CH2)
                reverb(msg[3], 0.5)
            elseif msg[2] == 75 then
                route(OP2, OP1, msg[3]/64)
            elseif msg[2] == 79 then
                route(OP3, OP2, msg[3]/64)
            elseif msg[2] == 72 then
                envelope(OP1, 0, 1, 0.9, msg[3]/64, 0.2, 1.0, 0)
            elseif msg[2] == 80 then
                envelope(OP2, 0, 1, 0.5, msg[3]/64, msg[3]/64, msg[3]/64, 0)
            else
                terminal_print(msg[2])
            end
        end
    end
end
