local NOM = require 'nibui.NOM'
local d = NOM.dynamic

return {
    x = d'+'(d'+'(d'left', d'/'(d'^''w', 6)), 124),
    y = d'+'(d'top', 82),
    w = 100, h = 24*3+4,
    id = 'desc',
}
