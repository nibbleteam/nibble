local prev_screen = ""
local quit = false

local x=0
local y=0
local vx=2
local vy=1
local dt=1

function init()
    prev_screen = kernel.read(544, 75*1024)
end

function draw()
    kernel.write(544, prev_screen)

    if not quit then
        rectf(x, y, 150, 70, 2)

        print("FPS: "..tostring(math.floor(1/dt+0.5)), x+94, y)
        print("Menu", x, y)
        print("v1", x, y+10)
        print("ENV PID: "..kernel.getenv("pid"), x, y+20)
        print("ENV APP.PID: "..kernel.getenv("app.pid"), x, y+30)

        print("\08 go back", x, y+50)
        print("\09 close cartridge", x, y+60)
    end
end

function update(delta)
    dt = delta
    if btp(RED) and kernel.getenv("app.pid") ~= "1" then
        kernel.read(154154, 32)
        kernel.write(544, prev_screen)
        kernel.kill(tonumber(kernel.getenv("app.pid")))
        kernel.kill(0)
        quit = true
    end

    if btp(BLUE) or (btp(RED) and kernel.getenv("app.pid") == "1") then
        kernel.read(154154, 32)
        kernel.write(544, prev_screen)
        kernel.setenv("menu.entry", "back")
        kernel.kill(0)
        quit = true
    end

    x = x+vx
    y = y+vy

    if x > 320-150 then
        vx = vx*-1
    end
    if x < 0 then
        vx = vx*-1
    end
    if y > 240-70 then
        vy = vy*-1
    end
    if y < 0 then
        vy = vy*-1
    end
end
