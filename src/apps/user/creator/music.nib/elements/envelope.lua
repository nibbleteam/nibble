local Easing = require("nibui.Easing")

return {
    ballx = 0, bally = 0,
    color = 6,
    draw = function (self)
        local x, y = self:get(self.x), self:get(self.y)
        local w, h = self:get(self.w), self:get(self.h)
        local bg = math.floor(self:get(self.background))
        local color = math.floor(self:get(self.color))

        local t = time()*8

        rectf(x, y, w, h, 16)
        rect(x, y, w, h, bg+4)

        circf(self:get(self.x)+self.ballx.value, self:get(self.y)+self.bally.value+3, 3, 1)
        circf(self:get(self.x)+self.ballx.value, self:get(self.y)+self.bally.value, 3, color)
        circf(self:get(self.x)+self.ballx.value+1, self:get(self.y)+self.bally.value-1, 1, 15)

        fm[2*self.index.value+1] = (self.ballx.value-self:get(self.x))/self:get(self.w)
        fm[2*self.index.value+2] = (self.bally.value-self:get(self.y))/self:get(self.h)
    end,
    onclick = function(self, event)
        self.ballx:set(event.x-self:get(self.x), 0.2, Easing.InOutCubic)
        self.bally:set(event.y-self:get(self.y), 0.2, Easing.InOutCubic)
    end,
    onmove = function(self, event)
        if event.drag then
            self.ballx:set(event.x-self:get(self.x), 0, Easing.InOutCubic)
            self.bally:set(event.y-self:get(self.y), 0, Easing.InOutCubic)
            self.color:set(math.random(1, 15), 0)
        end
    end,
}
