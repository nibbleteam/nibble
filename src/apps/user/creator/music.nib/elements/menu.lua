-- [ new ] [ save ]

local dynamic = require('nibui.NOM').dynamic
local iv = require("nibui.InterpolatedValue")
local Easing = require("nibui.Easing")

local settings = {
    {
        content = '\13',
        background = 5,
        onclick = function (self, event)
            if self.background ~= 5 then
                self.background = {5, 0.3}
                self.document:find('#envelopes'):open()
            else
                self.background = {12, 0.3}
                self.document:find('#envelopes'):close()
            end
        end,
    },
    {
        content = '\7',
        z = 0,
        onclick = function (self, event)
            if self.color ~= 6 then
                self.color = {6, 0.3}
            else
                self.color = {15, 0.3}
            end
        end,
    }
}

local nom = {
    x = dynamic 'left', y = dynamic 'top',
    w = #settings*12, h = 12,
}

for i, settings in ipairs(settings) do
    table.insert(nom, {
        x = dynamic '+' (dynamic '^' 'x', (i-1)*12+1),
        y = dynamic '+' (dynamic '^' 'y', 1),
        w = 10, h = 10,
        radius = 2,
        border_color = 0,
        background = settings.background or 12,
        content = settings.content,
        onclick = settings.onclick,
        onenter = function (self, event)
            self.border_color = 15
        end,
        onleave = function (self, event)
            self.border_color = 0
        end
    })
end

return nom
