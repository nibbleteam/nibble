local NOM = require("nibui.NOM")

nom = NOM:new(require("nom")):use("cursor")

require 'synth'

playing = false

RUNNING = true

function init()
    audio_init()

    nom:init()
end

function draw()
    if RUNNING then
        nom:draw()
    end
end

function update(dt)
    local msg = kernel.receive()

    if msg then
        if msg.running ~= nil then
            RUNNING = msg.running

            if RUNNING then
                nom.root:set_dirty()
            end
        end
    end

    if RUNNING then
        nom:update(dt)
        audio_update(dt)
    end
end
