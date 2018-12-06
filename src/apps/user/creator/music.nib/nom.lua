local Easing = require('nibui.Easing')
local NOM = require('nibui.NOM')
local d = NOM.dynamic

local border_size = 1
local taskbar_height = 16

local nom = {
    x = d'+' (d'^' 'x', border_size),
    y = d'+' (d'^' 'y', border_size),
    w = d'-' (d'^' 'w', 2*border_size),
    h = d'-' (d'^' 'h', 2*border_size+taskbar_height),
    background = 7,
    border_color = 6,
    d'=>' 'elements.header',
    d'=>' 'elements.app',
    d'=>' 'elements.status',
    {
        x = d'-' (d'left', border_size),
        y = d'+' (d'bottom', border_size),
        w = d'+' (d'^' 'w', 2*border_size),
        h = 1,
        background = 4
    },
}


return nom
