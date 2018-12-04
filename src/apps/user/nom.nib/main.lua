local NOM = require('nibui.NOM')
local dynamic = NOM.dynamic

local nom = NOM:new({
    x = dynamic '+' (dynamic 'left', dynamic '%' (25, 'w')),
    w = dynamic '%' (50, 'w'),
    y = dynamic '+' (dynamic 'top', dynamic '%' (25, 'h')),
    h = dynamic '%' (50, 'h'),
    border_color = 8,
}):use('cursor')

function draw()
    nom:draw()
end

function update(dt)
    nom:update(dt)
end
