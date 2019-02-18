local Easing = require('nibui.Easing')
local NOM = require('nibui.NOM')
local d = NOM.dynamic

local border_size = 1
local taskbar_height = 16

local nom = {
    x = d'+' (d'^' 'x', 0),
    y = d'+' (d'^' 'y', 0),
    w = d'-' (d'^' 'w', 0),
    h = d'-' (d'^' 'h', taskbar_height),
    background = 6,
    border_color = 6,
    d'=>' 'elements.header',
    d'=>' 'elements.app',
    d'=>' 'elements.status',
}


return nom
