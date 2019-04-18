local Easing = require('nibui.Easing')
local NOM = require('nibui.NOM')
local d = NOM.dynamic

local border_size = 1
local taskbar_height = 16

local nom = {
    x = d'^' 'x',
    y = d'^' 'y',
    w = d'^' 'w',
    h = d'-' (d'^' 'h', taskbar_height),
    background = 6,

    {
        x = d'+' (d'^' 'x', border_size),
        y = d'+' (d'^' 'y', border_size),
        w = d'-' (d'^' 'w', 2*border_size),
        h = d'-' (d'^' 'h', taskbar_height),
        background = 6,
        border_color = 6,
        d'=>' 'elements.header',
        d'=>' 'elements.app',
        d'=>' 'elements.status',
    }
}


return nom
