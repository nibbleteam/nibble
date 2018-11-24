-- [ icons ]             [ hamburguer ]

return {
    x = top(), y = left(),
    w = parent('w'), h = 12,
    background = 6,
    shadow_color = 4,
    z = 1,
    require('elements.menu'),
    {
        x = calc(right(), -12), y = parent('y'),
        w = 12, h = 12,
        radius = 6,
        background = 8,
        content = ' ',
        onclick = function (self, event)
            self.content = string.char(self.content:byte()+1)
            return true
        end,
        onenter = function (self, event)
            self.background = 12
        end,
        onleave = function (self, event)
            self.background = 0
        end
    }
}
