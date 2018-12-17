local NOM = require('nibui.NOM')
local Widget = require('nibui.Widget')
local d = NOM.dynamic

return {
    id = 'timeline',

    x = d'left', y = d'top',
    w = d'^' 'w', h = 12,
    background = 16,
    timeline = d'.''x',
    view_position = d'.''x',
    view_size = 0,

    update_position = function (self, position)
        self.timeline = position*self.w+self.x
    end,

    update_view = function (self, position, size)
        self.view_position = position*self.w+self.x
        self.view_size = size*self.w+1
    end,

    draw = function (self)
        Widget.draw(self)

        rect(self.view_position, self.y, self.view_size, self.h-1, 10)

        line(self.timeline, self.y, self.timeline, self.y+self.h, 15)

        line(self.x, self.y+self.h-1, self.w+self.x, self.y+self.h-1, 6)
    end,

    onclick = function (self, event)
        self.timeline = {event.x, 0.05}
        self.view_position = {event.x, 0.05}
        self:update_score(event.x)
    end,
    onmove = function (self, event)
        if event.drag then
            self.timeline = event.x
            self.view_position = event.x
    
            self:update_score(event.x)
        end
    end,

    update_score = function (self, x)
        local t = (x-self.x)/self.w

        self.document:find('#score'):set_time(t)
    end
}
