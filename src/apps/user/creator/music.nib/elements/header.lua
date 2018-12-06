local d = require('nibui.NOM').dynamic

return {
    x = d'top', y = d'left',
    w = d'^' 'w', h = 12,
    background = 6,
    shadow_color = 4,
    z = 1,
    d'=>' 'elements.menu',
    {
        x = d'-' (d'right', 12),
        y = d'^' 'y',
        w = 12, h = 12,
        radius = 6,
        content = '\17',
    }
}
