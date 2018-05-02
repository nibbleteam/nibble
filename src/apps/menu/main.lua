local prev_screen = ""
local quit = false

local x=0
local y=0
local vx=2
local vy=1

function init()
    prev_screen = kernel.read(544, 75*1024)
end

function draw()
    kernel.write(544, prev_screen)


    if not quit then
        rectf(x, y, 150, 70, 2)

        print("Nibble System Menu", x, y)
        print("v1", x, y+10)
        print("ENV PID: "..kernel.getenv("pid"), x, y+20)
        print("ENV APP.PID: "..kernel.getenv("app.pid"), x, y+30)

        print("\08 go back", x, y+50)
        print("\09 close cartridge", x, y+60)
    end
end

function update()
    if btp(RED) then
        kernel.read(154154, 32)
        kernel.write(544, prev_screen)
        kernel.exit(tonumber(kernel.getenv("app.pid")))
        kernel.exit(0)
        quit = true
    end

    if btp(BLUE) then
        kernel.read(154154, 32)
        kernel.write(544, prev_screen)
        kernel.exit(0)
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
