local prev_screen = ""

local x=320/2-160/2
local y=240/2-80/2
local vx=2
local vy=1
local dt=1

function init()
    prev_screen = read(768, 75*1024)
end

function draw()
    --write(768, prev_screen)

    fill_rect(x-2, y-2, 164, 84, 3)
    fill_rect(x, y, 160, 80, 2)

    local x = x + 4
    local y = y + 4

    print("FPS: "..tostring(math.floor(1/dt+0.5)), x+94, y)
    print("Menu", x, y)
    print("v1", x, y+10)
    print("ENV PID: "..env.pid, x, y+20)
    print("ENV APP.PID: "..env.app.pid, x, y+30)

    print("\08 go back", x, y+50)
    print("\09 close cartridge", x, y+60)
end

function update(delta)
    dt = delta or 1

    if button_press(RED) then
        stop_app(env.app.pid)
        return stop_app(0)
    end

    if button_press(BLUE) then
        env.menu = { entry = "back" }
        return stop_app(0)
    end
end
