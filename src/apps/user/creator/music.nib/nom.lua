return {
    x = calc(parent('x'), 1), y = calc(parent('y'), 1),
    w = calc(parent('w'), -2), h = calc(parent('h'), -2-16),
    background = 16,
    border_color = 6,
    require('elements.header'),
    require('elements.status'),
    onclick = function (self, event)
        self.background += 1
        self.border_color += 1
        return true
    end
}
