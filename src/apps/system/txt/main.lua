local shell
local t = 0

local tick = true
local tack = false

function init()
    shell = tonumber(kernel.getenv("shell"))
end

function update(delta)
    t = t + delta

    if math.floor(t)%2 == 0 and tick then
        tick = false
        tack = true
        kernel.send(shell, {print="Tick!"})
    end

    if math.floor(t)%2 == 1 and tack then
        tick = true 
        tack = false 
        kernel.send(shell, {print="Tack!"})
    end
end

function draw()
end
