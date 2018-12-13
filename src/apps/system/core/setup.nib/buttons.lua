local NOM = require 'nibui.NOM'
local d = NOM.dynamic

local button_height = 24
local button_radius = 2
local button_width = 100

local init_path = 'apps/system/core/init.nib/'

function copy_file(a, b)
    local mem_addr = kernel.memmap(a)
    kernel.memsync(mem_addr, b, true)
end

local button_defs = {
    {
        name = 'Play Mode',

        onclick = function ()
            copy_file(init_path..'conf.play.lua', init_path..'conf.lua')

            reboot = true
        end,
    },
    {
        name = 'Dev Mode',

        onclick = function ()
            copy_file(init_path..'conf.dev.lua', init_path..'conf.lua')

            reboot = true
        end,
    },
}

local buttons = {
    x = d'-'(d'+'(d'left', d'/'(d'^''w', 2)), button_width/2),
    y = d'+'(d'+'(d'^''y', 12), d'/'(d'^''h', 5)),
    w = d'*'(d'/'(d'^''w', 3), 2), h = d'*'(d'/'(d'^''h', 5), 3),
    buttons,
}

for b, button in ipairs(button_defs) do
    table.insert(buttons, {
        x = d'^''x', y = d'+'(d'top', (b-0.5)*2*button_height),
        w = button_width, h = button_height,
        border_color = 11,
        text_palette = 1,
        radius = button_radius,
        content = button.name,

        onenter = function (self)
            self.background = {11, 0.05}
        end,
        onleave = function (self)
            self.background = {0, 0.05}
        end,
        onclick = button.onclick,
    })
end

return buttons
