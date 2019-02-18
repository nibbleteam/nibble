-- Primeiro incluímos o NOM

local NOM = require 'nibui.NOM'

-- Em seguida damos um nome curto para `NOM.dynamic`,
-- que nos permite dar valores calculados em runtime
-- para os argumentos de elementos no `NOM`.

local d = NOM.dynamic

-- E antes de preparar o NOM, definimos também a altura
-- da taskbar.

local height = 16

-- Definimos quais ícones, onde estão e suas contra-cores:

local icons = {
    {'code', 7, 5},
    {'music', 6, 5},
    {'sprite', 8, 5},
}

-- Criamos o NOM para os ícones:

local nom = {
    x = d'left', y = d'-'(d'bottom', 16),
    w = d'^' 'w', h = height,
    background = 16,
    {
        id = 'line',
        x = d'left', y = d'top', w = d'^' 'w', h = 1,
        background = 4
    },
}

for i, icondef in ipairs(icons) do
    local name, sprite, color = icondef[1], icondef[2], icondef[3]
    
    table.insert(nom, {
        id = name,
        x = d'+'(d'left', 16*(i-1)),
        y = d'-'(d'top', 0),
        w = 16, h = height,
        background = {2, sprite},

        onenter = function (self)
            if running[name] then
                self.background = {0, sprite}
            else
                self.background = {1, sprite}
            end
        end,
        onleave = function (self)
            if not running[name] then
                self.background = {2, sprite}
            end
        end,
        onclick = function (self)
            run(name)

            self.document:find('#line').background = color
        end
    })
end

-- Finalmente criamos o NOM:

return nom
