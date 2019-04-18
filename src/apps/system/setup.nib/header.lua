local NOM = require 'nibui.NOM'
local d = NOM.dynamic

local header_height = 12

return {
    x = d'left', y = d'top',
    w = d'^' 'w', h = header_height,
    background = 11,
    content = 'Nibble Setup',
    text_palette = 1,
}
