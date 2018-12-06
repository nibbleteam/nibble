-- [ new ] [ save ]

local d = require('nibui.NOM').dynamic
local Easing = require("nibui.Easing")

local settings = {}

local nom = {
    x = d'left', y = d'top',
    w = #settings*12, h = 12,
}

for i, settings in ipairs(settings) do
    table.insert(nom, {
        x = d'+' (d'^' 'x', (i-1)*12+1),
        y = d'+' (d'^' 'y', 1),
        w = 10, h = 10,
        radius = 2,
        border_color = 0,
        background = settings.background or 12,
        content = settings.content,
        onclick = settings.onclick,
        onenter = settings.onenter,
        onleave = settings.onleave,
    })
end

return nom
