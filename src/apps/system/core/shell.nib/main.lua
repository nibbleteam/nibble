require("audio")
require("colors")
require("opening")
require("console")

local DecoratedText = require("nibui.DecoratedText")
local FormattedText = require("nibui.FormattedText")

local OPENING = 0
local READY = 1

local shell_state
local t

local cursor_active = 0
local user_input = "" 

local text = FormattedText:new(8, 8, 320-16, 240-16)

local prompt = DecoratedText:new("~")
               :set("color", 6):swap_colors()
local space = DecoratedText:new(" ")

audio_enable = true

function init()
    -- Copia a paleta padrão
    for i=1,7 do
        cppal(0, i)
    end

    -- Cor 0 transparente
    mask(0)
    
    shell_state = OPENING
    t = 0

    local about = DecoratedText:new("\13ibble shell")
                  :set("color", 11)
                  :set("bold", 5)

    text:add(about)
    text:newline()
    text:newline()
    text:add(prompt:copy()):add(space)

    clr(16)

    math.randomseed(time())

    --start_recording("Shell.gif")
end

function draw()
    if shell_state == OPENING then
        opening(0, t)
    elseif shell_state == READY then
        console(t)
    
        text:draw()

        draw_cursor()
    end
end

function draw_cursor()
    if cursor_active == 0 then
        if math.floor(t*3)%2 == 0 then
            rect(text.cursor_x, text.cursor_y, 4, 8, 15)
        end
    else
        rectf(text.cursor_x, text.cursor_y, 4, 8, 15)
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
    elseif shell_state == READY then
        receive_messages()

        local input = kernel.read(154410, 1)

        if #input > 0 then
            cursor_active = .5

            if input == "\08" then
                if #user_input > 0 then
                    text:delete(1)
                    user_input = user_input:sub(0, #user_input-1)
                end
            elseif input == "\13" then
                if #user_input > 0 then
                    text:newline()
                    execute(user_input)
                    user_input = "" 
                end
            else
                text:add(DecoratedText:new(input))
                user_input = user_input..input 
            end
        end

        if cursor_active > 0 then
            cursor_active -= dt
        else
            cursor_active = 0
        end
    end
end

function execute(cmd)
    local search_paths = {
        "apps/system/utilities/",
        "apps/user/demos/",
        "apps/user/creator/",
    }

    local found = false
    
    for _, search_path in ipairs(search_paths) do
        local path = search_path..cmd..".nib"

        dprint("shell exec " .. path)

        local child = kernel.exec(path, {})

        if child > 0 then
            kernel.kill(child)

            local monitor = kernel.exec("apps/system/core/monitor.nib", {
                shell = kernel.getenv("pid"),
                exec = path
            })

            kernel.wait(monitor)
            
            found = true

            break
        end
    end

    if not found then
        text:add(DecoratedText:new("No such file"):swap_colors())
        text:newline()
        text:add(prompt:copy()):add(space)
    end
end

function receive_messages()
    local message = kernel.receive()

    if message then
        if message.print and type(message.print) == "string" then
            text:add(DecoratedText:new(message.print))
            text:newline()
        end

        if message.app_started then
            audio_enable = false
        end

        if message.app_stopped then
            audio_enable = true
            
            text:newline()
            text:add(prompt:copy()):add(space)
        end
    end
end
