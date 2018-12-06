local NOM = require('nibui.NOM')
local Easing = require('nibui.Easing')
local d = NOM.dynamic

local lines = 12
local note_height = 12
local note_width = (320-2)/32

local width = 100
local height = lines*note_height

return {
    x = d'+'(d'/'(d'%' (100-width, 'w'), 2), d'^' 'x'),
    y = d'+'(d'^' 'y', 16),
    w = d'%' (width, 'w'), h = height,
    border_color = 1,
    dragging = false,

    quantize_pattern = function (self, x, y)
        local x = math.floor((x-self.x)/note_width)
        local y = math.floor((y-self.y)/note_height)

        return x, lines-y
    end,

    quantize = function (self, x, y)
        local x = math.floor((x-self.x)/note_width)*note_width+self.x
        local y = math.floor((y-self.y)/note_height)*note_height+self.y

        return x, y
    end,

    draw = function (self)
        for i=0,lines do
            local y = self.y+i*note_height

            line(self.x, y, self.x+self.w-2, y, self.border_color)
        end

        local  x = self.x
        while x < self.x+self.w do
            line(x, self.y, x, self.y+self.h, self.border_color+3)

            x += note_width
        end

        local sl = math.floor(tick/32*self.w)
        line(sl, self.y, sl, self.y+self.h, 15)

        if self.mouse and self.mouse.x and self.mouse.y then
            local x, y = self:quantize(self.mouse.x, self.mouse.y)

            if self.dragging then
                rectf(x, y, note_width, note_height, 6)
            end

            rect(x, y, note_width, note_height, 15)
        end

        for t=0,63 do
            for n=0,12*6-1 do
                if pattern[t] and pattern[t][n] then
                    local x = t*note_width+self.x
                    local y = (lines-(n-36))*note_height+self.y

                    rectf(x, y, note_width, note_height, 6)
                    rect(x, y, note_width, note_height, 15)
                end
            end
        end
    end,

    onclick = function (self, event)
        local px, py = self:quantize_pattern(event.x, event.y)

        if not pattern[px] then
            pattern[px] = {}
        end

        if pattern[px][py+36] then
            pattern[px][py+36] = nil
        else
            pattern[px][py+36] = true
        end

        self.dragging = false
    end,

    onmove = function (self, event)
        self.mouse = event

        if event.drag then
            self.dragging = true

            local px, py = self:quantize_pattern(event.x, event.y)

            if not pattern[px] then
                pattern[px] = {}
            end

            if pattern[px][py+36] then
                pattern[px][py+36] = nil
            end
        else
            self.dragging = false
        end
    end,

    onleave = function(self)
        self.mouse = nil
        self.dragging = false
    end,
}
