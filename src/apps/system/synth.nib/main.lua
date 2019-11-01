env.menu = {
    'Nibble Synth',
    'v0.1',
    '',
    'by Felipe Tavares'
}

local Text = require 'nibui.Text'
local Textarea = require 'nibui.Textarea'

local envelopes = {
    {
        freq = 1,
        inf = 0,
        volume = 1,
        sustain = 0,
        a = 0,
        d = 0,
        s = 0,
        r = 0
    },
    {
        freq = 1,
        inf = 0,
        volume = 1,
        sustain = 0,
        a = 0,
        d = 0,
        s = 0,
        r = 0
    },
    {
        freq = 0.5,
        inf = 15,
        volume = 1,
        sustain = 0,
        a = 0.05,
        d = 0.5,
        s = 1.0,
        r = 0.05
    },
    {
        freq = 1,
        inf = 1,
        volume = 1,
        sustain = 0,
        a = 0.05,
        d = 0.5,
        s = 1.0,
        r = 0.05
    },
}

local current_envelope, current_parameter = 1, 1

local messages = Textarea:new(8, 8, 400-16, 120)

local keys_num = 84
local pressed_keys = {}
local pressed_keys_frames = require 'pressed_keys'

local MIDI_NOTEOFF = 8
local MIDI_NOTEON = 9
local MIDI_PARAM = 11

local PARAM_WHEEL = 114
local PARAM_WHEEL_UP = 65
local PARAM_WHEEL_DOWN = 63
local PARAM_WHEEL_CLICK = 127
local PARAM_WHEEL_RELEASE = 0

local PARAM_A1 = 73
local PARAM_D1 = 75
local PARAM_S1 = 79
local PARAM_R1 = 72

local PARAM_A2 = 80
local PARAM_D2 = 81
local PARAM_S2 = 82
local PARAM_R2 = 83

local PARAM_M = 85

local PARAM_1 = 74
local PARAM_2 = 71
local PARAM_3 = 76
local PARAM_4 = 77
local PARAM_5 = 93
local PARAM_6 = 18
local PARAM_7 = 19
local PARAM_8 = 16
local PARAM_9 = 17

local envelope_offset = 3

local black_amount = {
    0, 1, 1, 2, 2, 2, 3, 3, 4, 4, 5, 5
}

local n_to_key = {
    true,
        false,
    true,
        false,
    true,
    true,
        false,
    true,
        false,
    true,
        false,
    true,
}

local display_log = false

function is_white(k)
    return n_to_key[k%12+1]
end

function black_key_amount(k)
    return black_amount[k%12+1]+math.floor(k/12)*5
end

function white_key_amount(k)
    return k%12-black_amount[k%12+1]+math.floor(k/12)*7
end

function white_key_n(k)
    return k-black_key_amount(k)
end

function key_to_pixel(k)
    local frame_data = pressed_keys_frames.frames[k+2]

    if frame_data then
        local frame = frame_data.frame
        local spriteSource = frame_data.spriteSourceSize

        return {spriteSource.x, spriteSource.y, frame.x, frame.y+240, frame.w, frame.h}
    else
        return nil
    end
end
function init()
    math.randomseed(time())

    write(0, '\x14\x0c\x1c\xff\x44\x24\x34\xff\x30\x34\x6d\xff\x4e\x4a\x4e\xff\x85\x4c\x30\xff\x34\x65\x24\xff\xd0\x46\x48\xff\x75\x71\x61\xff\x59\x7d\xce\xff\xd2\x7d\x2c\xff\x85\x95\xa1\xff\x6d\xaa\x2c\xff\xd2\xaa\x99\xff\x6d\xc2\xca\xff\xda\xd4\x5e\xff\xde\xee\xd6\xff')
    copy_palette(0, 1)
    mask_color(0)

    channel(CH2)
    -- Frequências
    freqs(1.0, 1.0, 1.0, 2.0)
    -- Envelopes
    envelope(OP1, 0, 1, 0.2, 0.01, 10, 0.1, 0)
    envelope(OP2, 0, 1, 0.2, 0.01, 10, 0.1, 0)
    envelope(OP3, 0, 1, 0.2, 0.01, 10, 0.1, 0)
    envelope(OP4, 0, 1, 0.2, 0.01, 10, 0.1, 0)
    -- Roteia
    route(OP1, OUT, 0.05)
    route(OP2, OP1, 2.0)
    route(OP3, OP1, 0.01)
    route(OP4, OP1, 0.01)

    channel(CH1)
    -- Frequências
    freqs(8.0, 1.0, 1.0, 1.0)
    -- Envelopes
    envelope(OP1, 0, 1, 0.5, 0.0, 0.1, 0.1, 0)
    envelope(OP2, 0, 1, 0.5, 0.0, 0.1, 0.1, 0)
    envelope(OP3, 0, 1, 0.5, 0.0, 0.2, 0.3, 0)
    envelope(OP4, 0, 1, 0.5, 0.0, 0.2, 0.3, 0)
    -- Roteia
    route(OP1, OP2, 1.0)
    route(OP2, OUT, 0.05)
    route(OP3, OP4, 0.3)
    route(OP4, OUT, 0.2)

    --channel(CH1)
    ----freqs(1.0, 1.0, 1.0, 1.0)

    ---- Frequências
    --if math.random() < 0.5 then
    --    freqs(math.random(), math.random(), math.random(), math.random())
    --else
    --    freqs(math.random(1, 8)/4, math.random(1, 8)/4, 1.0, math.random(1, 8)/4)
    --end
    ---- Envelopes
    --envelope(OP1, 0, 1, 0.5, math.random()*0.1, math.random(), math.random(), 0)
    --envelope(OP2, 0, 1, 0.5, math.random()*0.2, math.random(), math.random(), 0)
    --envelope(OP3, 0, 1, 0.5, math.random()*0.3, math.random(), math.random(), 0)
    --envelope(OP4, 0, 1, 0.5, math.random()*0.4, math.random(),math.random(), 0)
    ---- Roteia
    --route(OP1, OP2, 0.8)
    --route(OP2, OUT, 0.8)
    --route(OP2, OP3, 0.8)
    --route(OP3, OP4, 0.8)
    --route(OP4, OUT, 0.8)
    --
    channel(CH1)
    route(OP1, OP2, 0.0)
    route(OP2, OP3, 0.1)
    route(OP3, OP4, 15)
    route(OP4, OUT, 0.1)
end

function draw()
    clear(16)

    custom_sprite(40, 120, 0, 120, 320, 120)

    for k=0,keys_num do
        if pressed_keys[k] then
            press_key(k)
        end
    end

    for i=1,#envelopes do
        draw_envelope(200, 4+i*34, envelopes[i], 8+i, true)
    end

    if display_log then
        messages:draw()
    end

    if envelope_offset == 1 then
        print("LOW BANK", 4, 4)
    else
        print("HIGH BANK", 4, 4)
    end
end

function audio_tick()
    local input = read_keys()
    local octs = 'zsxdcvgbhnjmq2w3er5t6y7ui9o0p'

    for k=1,#input do
        -- Encontra a nota
        local note = octs:find(input:sub(k, k))

        if note ~= nil then
            note += 39-12

            -- Toca
            channel(CH1)
            noteon(note, 255)

            pressed_keys[note] = true
        end
    end

    local midi_messages = read_midi()

    local channels = {
        CH1, CH2, CH3, CH4, CH5, CH6, CH7, CH8
    }

    for _, msg in ipairs(midi_messages) do
        local cmd = math.floor(msg[1]/16)

        if cmd == MIDI_NOTEON then
            say('note on '..tostring(msg[2])..', '..tostring(msg[3]*2-1))

            local velocity = (msg[3]*2-1)*2

            if velocity > 255 then
                velocity = 255
            elseif velocity < 0 then
                say('note off '..tostring(msg[2]))

                local note = msg[2]

                if note > 255 then
                    note = 255
                elseif note < 0 then
                    note = 0
                end

                channel(channels[msg[1]%8])
                noteoff(note)

                pressed_keys[msg[2]] = false
            end

            if velocity > 0 then
                local note = msg[2]

                if note > 255 then
                    note = 255
                elseif note < 0 then
                    note = 0
                end

                channel(channels[msg[1]%8])
                noteon(note,  velocity)

                pressed_keys[msg[2]] = true
            end
        elseif cmd == MIDI_NOTEOFF then
            say('note off '..tostring(msg[2]))

            local note = msg[2]

            if note > 255 then
                note = 255
            elseif note < 0 then
                note = 0
            end

            channel(channels[msg[1]%8])
            noteoff(note)

            pressed_keys[msg[2]] = false
        elseif cmd == MIDI_PARAM then
            local param = msg[2]
            local value = msg[3]

            if param == PARAM_A1 then
                envelopes[envelope_offset].a = value/127
            elseif param == PARAM_D1 then
                envelopes[envelope_offset].d = value/127
            elseif param == PARAM_S1 then
                envelopes[envelope_offset].s = value/127
            elseif param == PARAM_R1 then
                envelopes[envelope_offset].r = value/127
            elseif param == PARAM_A2 then
                envelopes[envelope_offset+1].a = value/127
            elseif param == PARAM_D2 then
                envelopes[envelope_offset+1].d = value/127
            elseif param == PARAM_S2 then
                envelopes[envelope_offset+1].s = value/127
            elseif param == PARAM_R2 then
                envelopes[envelope_offset+1].r = value/127
            elseif param == PARAM_1 then
                route(OP1, OP2, value/127)
                envelopes[1].inf = value/127
            elseif param == PARAM_2 then
                route(OP2, OP3, value/127)
                envelopes[2].inf = value/127
            elseif param == PARAM_3 then
                route(OP3, OP4, value/127)
                envelopes[3].inf = value/127
            elseif param == PARAM_4 then
                route(OP4, OUT, value/127)
                envelopes[4].inf = value/127
            elseif param == PARAM_M then
                route(OP4, OUT, value/127)
                envelopes[4].inf = value/127
            elseif param == PARAM_5 then
                envelopes[1].freq = value/127
            elseif param == PARAM_6 then
                envelopes[2].freq = value/127
            elseif param == PARAM_7 then
                envelopes[3].freq = value/127
            elseif param == PARAM_8 then
                envelopes[4].freq = value/127
            elseif param == PARAM_WHEEL then
                if value == PARAM_WHEEL_UP then
                    envelope_offset = 3
                elseif value == PARAM_WHEEL_DOWN then
                    envelope_offset = 1
                end
            end
        end
    end

    write_parameters()

    handle_input()
end

function press_key(k)
    local spr = key_to_pixel(k)

    if spr then
      spr[1] += 40

      custom_sprite(unwrap(spr))
    end
end

function say(what)
    messages:add(Text:new(what))
    messages:newline()
end

function write_parameters()
    channel(CH1)

    local f = {};

    for i=1,#envelopes do
        local env = envelopes[i]

        envelope(OP1+i-1, 1, env.volume, env.a, env.d, env.s, env.r, 1)

        insert(f, env.freq)
    end

    freqs(unwrap(f))
end

function handle_input()
    local param = ({"a", "d", "s", "r"})[current_parameter]

    if button_press(DOWN) then
        current_envelope -= 1

        if current_envelope < 1 then
            current_envelope = #envelopes
        end
    end

    if button_press(UP) then
        current_envelope += 1

        if current_envelope > #envelopes then
            current_envelope = 1
        end
    end

    if button_down(RIGHT) then
        envelopes[current_envelope][param] += 0.01
    end

    if button_down(LEFT) then
        envelopes[current_envelope][param] = math.max(0, envelopes[current_envelope][param]-0.01)
    end

    if button_press(WHITE) then
        current_parameter -= 1

        if current_parameter < 1 then
            current_parameter = 4
        end
    end

    if button_press(BLACK) then
        current_parameter += 1

        if current_parameter > 4 then
            current_parameter = 1
        end
    end

    if button_press(RED) then
        display_log = not display_log
    end
end

function draw_envelope(x, y, env, color, blink)
    local scale_x, scale_y = 100, 20
    local ray = 2
    local sustain_time = 0

    local freq = tostring((math.floor(env.freq*100)/100))
               ..", "
               ..tostring((math.floor(env.inf*100)/100))

    print(freq, x-measure(freq)/2, y-30)

    x = x-(env.a+env.d+sustain_time+env.r)*scale_x/2

    --x = x-100

    local points = {
        {x, y},
        {x+env.a*scale_x, y-env.volume*scale_y},
        {x+(env.a+env.d)*scale_x, y-env.s*scale_y},
        {x+(env.a+env.d+sustain_time)*scale_x, y-env.s*scale_y},
        {x+(env.a+env.d+sustain_time+env.r)*scale_x, y},
    }

    for i, point in ipairs(points) do
        if blink then
            if current_parameter == i-1 then
                fill_circ(point[1], point[2], ray+math.sin(clock()*8)*ray, color)
            else
                circ(point[1], point[2], ray+math.sin(clock()*8)*ray, color)
            end
        else
            circ(point[1], point[2], ray, color)
        end
    end

    for i=2,#points do
        local p1 = points[i-1]
        local p2 = points[i]

        line(p1[1], p1[2], p2[1], p2[2], color)
    end
end
