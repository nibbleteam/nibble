local Easing = require 'nibui.Easing'
local NOM = require 'nibui.NOM'
local d = NOM.dynamic

local ui = NOM:new({
    x = 0, y = 0,
    w = 320, h = 240,
    background = 8,

    {
        x = 0, y = 0,
        w = 320, h =  12,
        background = 9,

        content='hello',

        init = function (self)
            --self.y = {self.parent.h-self.h, 1, Easing.InOutCubic}
        end,

        onenter = function(self)
            self.background = {0, 0.5}
        end,

        onleave = function(self)
            self.background = {9, 0.5}
        end
    },
}):use('cursor')

function init()
    ui:init()
end

function draw()
    ui:draw()
end

function update(dt)
    ui:update(dt)
end
