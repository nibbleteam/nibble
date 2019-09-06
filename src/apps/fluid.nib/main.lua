env.menu = {
    'Nibble Fluid Sim',
    'v1.0',
    '',
    'by Felipe Tavares'
}

local buffer = {}
local dirs = {
    {0, 1},
    {1, 0},
    {1, 1},
    {-1, 1},
    {-1, 0},
    {1, -1},
    {0, -1},
    {-1, -1},
}
local W = 80
local H = 60

function math.round(x)
    if x > 0 then
        return math.ceil(x)
    else
        return math.floor(x)
    end
end

function iround(x)
    if x > 0 then
        return math.floor(x)
    else
        return math.ceil(x)
    end
end

function genline()
    local line = {}

    for i=1,W do
        local dir = dirs[math.floor(math.random()*#dirs+1)]
        insert(line, {0, dir[1], dir[2]})
    end

    return line
end

function init()
    for i=1,H do
        insert(buffer, genline())
    end
end

function get(x, y)
    if x > 0 and x <= W and
       y > 0 and y <= H then
        return buffer[math.floor(y)][math.floor(x)]
    else
        return {0, 0, 0}
    end
end

function set(x, y, v)
    if x > 0 and x <= W and
       y > 0 and y <= H then
        buffer[math.floor(y)][math.floor(x)] = v
    end
end

local prevx = 0
local prevy = 0

function update()
    for x=W,1,-1 do
        for y = 1,H do
            local i = math.sqrt(buffer[y][x][2]*buffer[y][x][2]+buffer[y][x][3]*buffer[y][x][3])

            local ax = x+iround(math.round(buffer[y][x][2]/i*4)/2)
            local ay = y+iround(math.round(buffer[y][x][3]/i*4)/2)
            if ax >= 1 and ax <= W and
               ay >= 1 and ay <= H then
                if buffer[y][x][1] > 0 then
                    buffer[ay][ax][1] = buffer[ay][ax][1]+i*buffer[y][x][1]
                buffer[y][x][1] = buffer[y][x][1]-i*buffer[y][x][1]
                end

                buffer[ay][ax][2] = buffer[ay][ax][2]+buffer[y][x][2]*0.3
                buffer[ay][ax][3] = buffer[ay][ax][3]+buffer[y][x][3]*0.3
                buffer[y][x][2] = buffer[y][x][2]-buffer[y][x][2]*0.3
                buffer[y][x][3] = buffer[y][x][3]-buffer[y][x][3]*0.3
            end

            if buffer[y][x][1] > 0 then
                --buffer[y][x][1] = buffer[y][x][1]-i*buffer[y][x][1]
            end

            if buffer[y][x][3] > 1 then
                buffer[y][x][3] = 1
            end
            if buffer[y][x][3] < -1 then
                buffer[y][x][3] = -1
            end
            if buffer[y][x][2] > 1 then
                buffer[y][x][2] = 1
            end
            if buffer[y][x][2] < -1 then
                buffer[y][x][2] = -1
            end

            if buffer[y][x][1] > 0 then
                local amount = buffer[y][x][1]*0.2

                if x+1 <= W then
                    local cellTo = get( x+1, y)
                    set(x+1, y, {cellTo[1]+amount, cellTo[2], cellTo[3]})
                    buffer[y][x][1] = buffer[y][x][1] - amount
                end
                if x-1 >= 1 then
                    local cellTo = get(x-1, y)
                    set(x-1, y, {cellTo[1]+amount, cellTo[2], cellTo[3]})
                    buffer[y][x][1] = buffer[y][x][1] - amount
                end

                if y+1 <= H then
                    local cellTo = get(x, y+1)
                    set(x, y+1, {cellTo[1]+amount, cellTo[2], cellTo[3]})
                    buffer[y][x][1] = buffer[y][x][1] - amount
                end
                if y-1 >= 1 then
                    local cellTo = get(x, y-1)
                    set(x, y-1, {cellTo[1]+amount, cellTo[2], cellTo[3]})
                    buffer[y][x][1] = buffer[y][x][1] - amount
                end
            end
        end
    end

    local mx, my = mouse_position()

    if mouse_button_down(MOUSE_LEFT) then
        local v = get(mx, my)
        local dx, dy = (mx-prevx)*0.5, (my-prevy)*0.5
        local w = 320/W
        local h = 240/H

        set(math.floor(mx/w), math.floor(my/h), {v[1]+100, v[2]+dx, v[3]+dy})
    end

    if mouse_button_down(MOUSE_RIGHT) then
        local v = get(mx, my)
        local dx, dy = (mx-prevx)*0.5, (my-prevy)*0.5
        local w = 320/W
        local h = 240/H

        set(math.floor(mx/w), math.floor(my/h), {v[1]-50, v[2]+dx, v[3]+dy})
    end

    prevx = mx
    prevy = my
end

function draw()
    if #buffer ~= H then
        return
    end

    local w = 320/W
    local h = 240/H

    clear(1)
    for y=1,H do
        for x=1,W do
            local v = buffer[y][x][1]
            local dx = buffer[y][x][2]
            local dy = buffer[y][x][3]

            local px = x*w-w/2
            local py = y*h-h/2

            if v > 15 then
                v = 15
            elseif v < 0 then
                v = 0
            else
                v = math.floor(v)
            end

            --rect(px-v/2, py-v/2, v, v, v)
            circ(px, py, v/2, v)
            --line(px, py, px+dx*v, py+dy*v, v) 
        end
    end

    custom_sprite(prevx, prevy, 56, 80, 8, 8)
end
