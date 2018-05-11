-- Nibble UI
local ui = {}

ui.Button = {
    state = {
        outColor = 9,
        inColor = 3,
        shadowColor = 0,
        x = 100, y = 100,
        height = 10,
        r = 10,
        w = 120,
        h = 40,
        text = "Button Demo"
    }
}

function ui.Button:draw()
    local x, y = self.state.x, self.state.y
    local w, h = self.state.w, self.state.h
    local r = self.state.r
    local text = self.state.text
    local inColor = self.state.inColor
    local shadowColor = self.state.shadowColor
    local outColor = self.state.outColor
    local height = self.state.height

    rectf(x+r, y+height, w-r*2, h, shadowColor)
    rectf(x, y+r+height, w, h-r*2, shadowColor)

    circf(x+r, y+r+height, r, shadowColor)
    circf(x+w-r, y+r+height, r, shadowColor)
    circf(x+r, y+h-r+height, r, shadowColor)
    circf(x+w-r, y+h-r+height, r, shadowColor)

    rect(x+r, y-1, w-r*2+1, h+1, outColor)
    rect(x, y+r-1, w+1, h-r*2+1, outColor)

    circf(x+r, y+r, r+1, outColor)
    circf(x+w-r, y+r, r+1, outColor)
    circf(x+r, y+h-r, r+1, outColor)
    circf(x+w-r, y+h-r, r+1, outColor)

    rectf(x+r, y, w-r*2, h, inColor)
    rectf(x, y+r, w, h-r*2, inColor)

    circf(x+r, y+r, r, inColor)
    circf(x+w-r, y+r, r, inColor)
    circf(x+r, y+h-r, r, inColor)
    circf(x+w-r, y+h-r, r, inColor)

    print(text, x+w/2-#text/2*8, y+h/2-4)
end

local t = 0
function ui.Button:update()
    t = t+1/30

    self.state.r = math.abs(math.sin(t))*20
    self.state.x = 100+math.sin(t)*100
    self.state.y = 100+math.cos(t)*100
    self.state.height = math.abs(math.sin(t))*8
end

return ui
