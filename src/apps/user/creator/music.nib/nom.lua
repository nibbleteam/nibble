local Easing = require("nibui.Easing")

local envelopes_w = 60

local envelopes = {
    id = 'envelopes',
    x = parent('x'), y = parent('y'),
    w = envelopes_w, h = parent('h'),
    _open = function(self)
        self.x:set(self:bind(parent('x')), 0.3, Easing.InCubic)
    end,
    _close = function(self)
        self.x:set(self:bind(calc(self:bind(parent('x')), -envelopes_w-1)), 0.3, Easing.OutCubic)
    end,
}

for i=0,3 do
    table.insert(envelopes, extend('elements.envelope', {
        x = parent('x'), y = percent('y', 'h', 25*i),
        w = parent('w'), h = percent('h', 25.5),
        background = 16+i,
        index = i,
    }));
end

local app = {
    x = parent('x'), y = calc(parent('y'), 13),
    w = parent('w'), h = calc(parent('h'), -25),
    envelopes
}


local nom = {
    x = calc(parent('x'), 1), y = calc(parent('y'), 1),
    w = calc(parent('w'), -2), h = calc(parent('h'), -2-16),
    background = 7,
    border_color = 6,
    require('elements.header'),
    app,
    require('elements.status'),
    {
        x = calc(parent('x'), -1), y = calc(bottom(), 1),
        w = calc(parent('w'), 2), h = 1,
        background = 4
    },
}


return nom
