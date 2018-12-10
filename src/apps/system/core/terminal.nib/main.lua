local Textarea = require('nibui.Textarea')
local Text = require('nibui.Text')

local cursor_active = 0
local user_input = "" 

local text = Textarea:new(8, 8, 320-16, 200)

local listeners = {}

local t = 0

local disabled = false

function init()
    -- Copia a paleta padrão
    for i=1,7 do
        cppal(0, i)
    end

    -- Cor 0 transparente
    mask(0)
end

function draw()
    if not disabled then
        clr(16)

        text:draw()

        draw_cursor()

        rect(8, 240-24, 320-16, 16, 1)
        print(status_line(), 12, 220)
    end
end

function listeners_line()
    local line = ''

    for pid, name in pairs(listeners) do
        line = line..('\12 '..name..'('..tostring(pid)..')')
    end

    if line ~= '' then
        --line = line..' @ terminal.nib(' .. kernel.getenv('pid') .. ') '
    else
        line = '...'
    end

    return line
end

function status_line()
    return listeners_line()
end

function draw_cursor()
    if cursor_active == 0 then
        if math.floor(t*2)%2 == 0 then
            rect(text.cursor_x, text.cursor_y, 4, 8, 15)
        end
    else
        rectf(text.cursor_x, text.cursor_y, 4, 8, 15)
    end
end

function update(dt)
    t += dt

    receive_messages()

    if not disabled and has_listeners() then
        local input = kernel.read(81606, 1)

        if input:byte() > 0 then
            cursor_active = .5

            if input == "\08" then
                if #user_input > 0 then
                    text:delete(1)
                    user_input = user_input:sub(0, #user_input-1)
                end
            elseif input == "\13" then
                text:newline()

                send_to_listeners(user_input)

                user_input = "" 
            elseif input == '\18' then
            else
                text:add(Text:new(input))
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

function has_listeners()
    for _, _ in pairs(listeners) do
        return true
    end
end

function lineiter(s)
    if s:sub(-1)~="\n" then s=s.."\n" end
    return s:gmatch("(.-)\n")
end

function add_text(str, bg, fg, swap)
    local line = ''

    for i=1,#str  do
        local c = str:sub(i, i)

        if c == '\n' then
            local new = Text:new(line)

            if bg then
                new:set('background_color', bg)
            end

            text:add(new)
            text:newline()
            line = ''
        else
            line ..= c
        end
    end

    if #line > 0 then
        local new = Text:new(line)

        if bg then
            new:set('background_color', bg)
        end

        text:add(new)
    end
end

function send_to_listeners(text)
    for listener, _ in pairs(listeners) do
        kernel.send(listener, {input=text})
    end
end

function receive_messages()
    local message = kernel.receive()

    if message then
        if message.print and type(message.print) == "string" then
            add_text(message.print, message.background)
        end

        if message.subscribe and type(message.subscribe) == "number" then
            listeners[message.subscribe] = message.name
        end

        if message.unsubscribe and type(message.unsubscribe) == "number" then
            listeners[message.unsubscribe] = nil
        end

        if message.disable then
            disabled = true
        end

        if message.enable then
            disabled = false
        end
    end
end
