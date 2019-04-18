local x = 0
local y = 0
local clicks = {}

function init()
end

function draw()
    print(tostring(x)..","..tostring(y), 260, 0)

    for i=#clicks,1,-1 do
        circ(clicks[i][1], clicks[i][2], clicks[i][3], i+2)

        clicks[i][3] = clicks[i][3]+5

        if clicks[i][3] > 50 then
            table.remove(clicks, i)
        end
    end

    pspr(x, y, 56, 80, 8, 8)
end

function update()
    x = read16(154442)
    y = read16(154444)

    if read8(154446) == 2 then
        table.insert(clicks, {x+4, y, 0})
    end
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
