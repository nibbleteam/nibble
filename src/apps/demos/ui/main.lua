local ui = require('niblib/ui')

local x = 0
local y = 0

function init()
end

function draw()
    clr(1)
    ui.Button:draw()
    pspr(x, y, 56, 80, 8, 8)
end

function update()
    x = read16(154186)
    y = read16(154188)

    if read8(154190) == 2 then
    end

    ui.Button:update()
end

function read16(p)
    local data = kernel.read(p, 2)
    local value = data:byte(2)
    value = value+data:byte(1)*256
    return value
end

function read8(p)
    local data = kernel.read(p, 1)
    return data:byte(1)
end
