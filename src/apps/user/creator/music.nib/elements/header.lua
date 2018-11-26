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
        content = '\17',
        onenter = function (self, event)
            self.color = 1
        end,
        onleave = function (self, event)
            self.color = 15
        end,
    }
}
