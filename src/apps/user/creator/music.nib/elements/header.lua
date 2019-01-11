local d = require('nibui.NOM').dynamic

return {
    id = 'header',

    x = d'top', y = d'left',
    w = d'^' 'w', h = 12,
    background = 6,
    d'=>' 'elements.menu',
}
