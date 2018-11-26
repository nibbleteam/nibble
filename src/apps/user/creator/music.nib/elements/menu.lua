-- [ new ] [ save ]

local iv = require("nibui.InterpolatedValue")
local Easing = require("nibui.Easing")

local settings = {
    {
        content = '\13',
        background = 5,
        onclick = function (self, event)
            if self.background.value ~= 5 then
                self.background:set(5, 0.1, Easing.InOutCubic)

                self.document:find('#envelopes'):_open()
            else
                self.background:set(12, 0.1, Easing.InOutCubic)

                self.document:find('#envelopes'):_close()
            end
        end,
    },
    {
        content = '\7',
        onclick = function (self, event)
            if self.color.value ~= 6 then
                self.color:set(6, 0.1, Easing.InCubic)
            else
                self.color:set(15, 0.1, Easing.OutCubic)
            end
        end,
    }
}

local nom = {
    x = left(), y = top(),
    w = #settings*12, h = 12,
}

for i, settings in ipairs(settings) do
    table.insert(nom, {
        x = calc(parent('x'), (i-1)*12+1), y = calc(parent('y'), 1),
        w = 10, h = 10,
        radius = 2,
        background = settings.background or 12,
        content = settings.content,
        onclick = settings.onclick,
        onenter = function (self, event)
            self.border_color:set(15, 0.1)
        end,
        onleave = function (self, event)
            self.border_color:set(0, 0.1)
        end
    })
end

return nom
