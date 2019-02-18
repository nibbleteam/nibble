# Code


    local NOM = require 'nibui.NOM'

    nom = NOM:new({
        w = 320,
        h = 240-16,
        x = 0, y = 0,
        background = 14,
    }):use('cursor')

    RUNNING = true

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
