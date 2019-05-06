local Text = require 'nibui.Text'
local Textarea = require 'nibui.Textarea'

local messages = Textarea:new(8, 8, 320-16, 120)

local audio_command_ptr = 0

local keys_num = 84
local pressed_keys = {}
local pressed_keys_frames = require 'pressed_keys'

local MIDI_NOTEOFF = 8
local MIDI_NOTEON = 9

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
    copy_palette(0, 1)
    mask_color(0)

    channel(CH1)
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
end

function draw()
    clear(16)

    custom_sprite(0, 120, 0, 120, 320, 120)

    for k=0,keys_num do
        if pressed_keys[k] then
            press_key(k)
        end
    end

    --messages:draw()
end

function update(dt)
    local midi_messages = read_midi()

    for _, msg in ipairs(midi_messages) do
        local cmd = math.floor(msg[1]/16)

        if cmd == MIDI_NOTEON then
            say('note on '..tostring(msg[2])..', '..tostring(msg[3]*2-1))

            local velocity = (msg[3]*2-1)*2

            if velocity > 255 then
                velocity = 255
            end

            channel(CH1)
            noteon(msg[2], audio_command_ptr%16, velocity)
            audio_command_ptr += 1

            pressed_keys[msg[2]] = true
        elseif cmd == MIDI_NOTEOFF then
            say('note off '..tostring(msg[2]))

            channel(CH1)
            noteoff(msg[2], audio_command_ptr%16)
            audio_command_ptr += 1

            pressed_keys[msg[2]] = false
        end
    end
end

function press_key(k)
    local spr = key_to_pixel(k)

    if spr then
        custom_sprite(unwrap(spr))
    end
end

function say(what)
    messages:add(Text:new(what))
    messages:newline()
end
