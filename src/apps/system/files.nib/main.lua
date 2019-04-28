local NOM = require 'nibui.NOM'
local nom = NOM:new(require 'nom'):use('cursor')

function draw()
    nom:draw()
end

function update(dt)
    nom:update(dt)
end

