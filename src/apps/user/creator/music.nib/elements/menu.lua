-- [ new ] [ save ]

local icons = {
    '\13', '\7'
}

local nom = {
    x = left(), y = top(),
    w = #icons*12, h = 12,
}

for i, icon in ipairs(icons) do
    table.insert(nom, {
        x = calc(parent('x'), (i-1)*12+1), y = calc(parent('y'), 1),
        w = 10, h = 10,
        radius = 5,
        content = icon,
        onclick = function (self, event)
            self.content = string.char(self.content:byte()+1)
        end,
        onenter = function (self, event)
            self.background = 12
        end,
        onleave = function (self, event)
            self.background = 0
        end
    })
end

return nom
