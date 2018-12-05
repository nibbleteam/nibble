local NOM = require('nibui.NOM')
local dynamic = NOM.dynamic

local nom = NOM:new({
    x = dynamic '^' 'x',
}):use('cursor')

function init()
    dprint(nom.root.x)
end

function draw()
end

function update(dt)
end
