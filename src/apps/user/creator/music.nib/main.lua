local NOM = require("nibui.NOM")

local nom = NOM:new(require("nom")):use("cursor")

beep = {}
delay = 0

require("synth")

function init()
    audio_init()

    clr(8)
end

function draw()
    nom:draw()
end

function update(dt)
    nom:update(dt)

    -- Cute sounds
    if nom.mouse.click == 1 then
        table.insert(beep, 40)
    elseif nom.mouse.click == 3 then
        table.insert(beep, 38)
    end
end
