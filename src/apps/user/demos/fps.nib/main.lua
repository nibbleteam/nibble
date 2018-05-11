local x = 0
local y = 0
local fps = ""

function init()
end

function draw()
    print(fps, 300, 232)
end

function update(dt)
    fps = tostring(math.floor(1/dt+0.5))
end
