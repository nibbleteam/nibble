require("audio")
require("colors")
require("opening")
require("console")

local OPENING = 0
local READY = 1

local shell_state
local t

function init()
    -- Copia a paleta padrão
    for i=1,7 do
        copypalette(0, i)
    end

    -- Cor 0 transparente
    transparent(0)
    
    shell_state = OPENING
    t = 0
end

function draw()
    if shell_state == OPENING then
        opening(0, t)
    elseif shell_state == READY then
        console(t)

        for i=0,15 do
            route_draw_color(15, 128+i);
            print("nib", 8, 8+i*8, 0)
        end

        for i=0,15 do
            route_screen_color(i, math.floor(t+i))
        end
    end
end

function update(dt)
    if dt <= 1/15 then
        t += dt
    end

    if shell_state == OPENING then
        if t > 0.5 then
            shell_state = READY
        end
    end
end
