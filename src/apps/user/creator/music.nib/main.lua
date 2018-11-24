local NOM = require("nibui.NOM")

local nom = NOM:new(require("nom")):use("cursor")

local beep = {}
local delay = 0

function audio_tick()
    if #beep > 0 and delay == 0 then
        -- Frequencies
        kernel.write(154448, '\xff\x80')
        -- No sustain + envelopes
        kernel.write(154448+4, '\x00\xc0\x01\x01\x60\x01')
        kernel.write(154448+10, '\x00\xc0\x03\x01\x60\x01')
        -- Routing table
        kernel.write(154448+4+4*6+0*5+1, string.char(60))
        kernel.write(154448+4+4*6+1*5+4, string.char(255))

        -- A4, note on
        kernel.write(154448+48, '\x01'..string.char(beep[1]));

        table.remove(beep, 1)

        delay = 4
    end

    if delay > 0 then
        delay = delay-1
    end
end

function init()
    cppal(0, 1)
    mask(0)
    clr(1)
end

function draw()
    nom:draw()
end

function update(dt)
    nom:update()

    -- Cute sounds
    if nom.mouse.click == 1 then
        table.insert(beep, 30)
    elseif nom.mouse.click == 3 then
        table.insert(beep, 28)
    end
end
