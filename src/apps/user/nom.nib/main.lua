local NOM = require('nibui.NOM')
local dynamic = NOM.dynamic

local nom = NOM:new({
    var_with_custom_name = 16,
}):use('cursor')

function init()
    nom.root.var_with_custom_name = {8, 0}

    nom:update(1)

    dprint(nom.root.var_with_custom_name)
end

function draw()
end

function update(dt)
end
