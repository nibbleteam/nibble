local prev_screen = ""

local x=320/2-160/2
local y=240/2-80/2
local vx=2
local vy=1
local dt=1

function init()
    prev_screen = kernel.read(800, 75*1024)
end

function draw()
    --kernel.write(544, prev_screen)

    rectf(x-2, y-2, 164, 84, 3)
    rectf(x, y, 160, 80, 2)

    local x = x + 4
    local y = y + 4

    print("FPS: "..tostring(math.floor(1/dt+0.5)), x+94, y)
    print("Menu", x, y)
    print("v1", x, y+10)
    print("ENV PID: "..kernel.getenv("pid"), x, y+20)
    print("ENV APP.PID: "..kernel.getenv("app.pid"), x, y+30)

    print("\08 go back", x, y+50)
    print("\09 close cartridge", x, y+60)
end

function update(delta)
    dt = delta

    if btp(RED) and kernel.getenv("app.pid") ~= "2" then
        kernel.kill(tonumber(kernel.getenv("app.pid")))
        kernel.kill(0)
        return
    end

    if btp(BLUE) or (btp(RED) and kernel.getenv("app.pid") == "2") then
        kernel.setenv("menu.entry", "back")
        kernel.kill(0)
        return
    end
end
