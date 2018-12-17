local NOM = require 'nibui.NOM'
local d = NOM.dynamic

local height = 16

return {
    x = d'left', y = d'-'(d'bottom', 16),
    w = d'^' 'w', h = height,
    background = 16,
    {
        x = d'left', y = d'top', w = d'^' 'w', h = 1,
        background = 4
    },
    {
        id = 'music',
        x = d'left', y = d'-'(d'top', 0),
        w = 16, h = height,
        background = {0, 6},

        onenter = function (self)
            background = {0, 5}
        end,
        onleave = function (self)
            background = {0, 6}
        end
    },
}
