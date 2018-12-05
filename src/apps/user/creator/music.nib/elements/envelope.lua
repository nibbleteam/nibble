local Easing = require("nibui.Easing")

return {
    ballx = 0, bally = 0,
    color = 6,
    draw = function (self)
        local x, y = self.x, self.y
        local w, h = self.w, self.h
        local bg = math.floor(self.background)
        local color = math.floor(self.color)

        local t = time()*8

        rectf(x, y, w, h, 16)
        rect(x, y, w, h, bg+4)

        circf(self.x+self.ballx, self.y+self.bally+3, 3, 1)
        circf(self.x+self.ballx, self.y+self.bally, 3, color)
        circf(self.x+self.ballx+1, self.y+self.bally-1, 1, 15)

        --fm[2*self.index.value+1] = (self.ballx.value-self.x)/self.w
        --fm[2*self.index.value+2] = (self.bally.value-self.y)/self.h
    end,
    onclick = function(self, event)
        self.ballx = event.x-self.x
        self.bally = event.y-self.y
    end,
    onmove = function(self, event)
        if event.drag then
            self.ballx = event.x-self.x
            self.bally = event.y-self.y

            self.color = math.random(1, 15)
        end
    end,
}
