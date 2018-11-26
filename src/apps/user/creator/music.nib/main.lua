local NOM = require("nibui.NOM")

local nom = NOM:new(require("nom")):use("cursor")

beep = {}
delay = 0

require("synth")

function init()
    cppal(0, 1)
    mask(0)

    audio_init()

    clr(16)

    start_recording('nibui.gif')
end

function draw()
    nom:draw()
end

function update(dt)
    audio_tick(dt)

    nom:update(dt)

    -- Cute sounds
    if nom.mouse.click == 1 then
        table.insert(beep, 40)
    elseif nom.mouse.click == 3 then
        table.insert(beep, 38)
    end
end
