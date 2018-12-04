local dynamic = require('nibui.NOM').dynamic

return {
    x = dynamic 'top', y = dynamic 'left',
    w = dynamic '^' 'w', h = 12,
    background = 6,
    shadow_color = 4,
    z = 1,
    dynamic '=>' ('elements.menu', {}),
    {
        x = dynamic '-' (dynamic 'right', 12),
        y = dynamic '^' 'y',
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
