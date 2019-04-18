-- play/pause 

local d = require('nibui.NOM').dynamic
local Easing = require("nibui.Easing")

local settings = {
    {
        background = {80, 0, 8, 8},

        onclick = function(self)
            playing = not playing

            if playing then
                self.background = {88, 0, 8, 8}
            else
                self.background = {80, 0, 8, 8}
            end
        end,

        onenter = function (self)
            self.color = 1
        end,
        onleave = function (self)
            self.color = 15
        end
    },
}

local nom = {
    x = d'left', y = d'top',
    w = #settings*12, h = 12,
}

for i, settings in ipairs(settings) do
    table.insert(nom, {
        x = d'+' (d'^' 'x', (i-1)*12+1),
        y = d'+' (d'^' 'y', 2),
        w = 9, h = 9,
        radius = 2,
        border_color = settings.border_color or 0,
        background = settings.background or 12,
        content = settings.content,
        onclick = settings.onclick,
        onenter = settings.onenter,
        onleave = settings.onleave,
    })
end

return nom
