local NOM = require 'nibui.NOM'
local d = NOM.dynamic

nom = NOM:new({
    w = 320,
    h = 240-16,
    x = 0, y = 0,
    background = 11,
    d '=>' 'editor'
}):use('cursor')

RUNNING = true

function init()
    start_recording('code.nib.gif')
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
    end
end
