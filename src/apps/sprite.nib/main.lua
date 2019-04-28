local NOM = require 'nibui.NOM'

nom = NOM:new({
    w = 320,
    h = 240-16,
    x = 0, y = 0,
    background = 14,
}):use('cursor')

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
end
