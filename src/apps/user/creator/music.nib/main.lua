local NOM = require("nibui.NOM")

nom = NOM:new(require("nom")):use("cursor")

require 'synth'

playing = false

function init()
    audio_init()

    nom:init()
end

function draw()
    nom:draw()
end

function update(dt)
    nom:update(dt)
    audio_update(dt)
end
