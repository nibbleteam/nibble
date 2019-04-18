local NOM = require 'nibui.NOM'
local d = NOM.dynamic

return {
    x = d'left', y = d'top',
    w = d'^' 'w', h = d'^' 'h',
    background = 0,

    d'=>' 'header',
    d'=>' 'buttons',
}
