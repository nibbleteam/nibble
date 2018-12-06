local NOM = require("nibui.NOM")

local nom = NOM:new(require("nom")):use("cursor")

require 'synth'

function init()
    cppal(0, 1)

    mask(0)

    clr(16)

    audio_init()
end

function draw()
    nom:draw()
end

function update(dt)
    nom:update(dt)
end
