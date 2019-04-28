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
    local msg = receive_message()

    if msg then
        if msg.resume then
            nom.root:set_dirty()
        end
    end

    nom:update(dt)
    audio_update(dt)
end
