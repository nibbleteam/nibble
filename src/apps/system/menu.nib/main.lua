require 'nibui.Neact'
local NOM = require 'nibui.NOM'
local Dialog = require 'uikit.Dialog'
local Button = require 'uikit.Button'

local Menu = Neact.Component:new()

local menu, nom = nil, nil

local visible = true

function Menu:new(props)
    return new(Menu, {
                   props = props,
                   state = copy(props),
    })
end

function Menu:render(state, props)
    local body = {}

    if env.app.env.menu then
        for k, v in ipairs(env.app.env.menu) do
            push(body, {
                     x = NOM.left, y = NOM.top+16*k, w = NOM.width, h = 16,
                     content = v,
            })
        end
    end

    return {
        x = NOM.top, y = NOM.h,
        w = NOM.parent.w, h = NOM.parent.h,

        --background = 14,

        {Dialog, w = 160, h = 128, header = {
             {
                 x = NOM.left, y = NOM.top, w = NOM.width, h = NOM.height,
                 content = state.time
             },
             {
                 Button, key = 'close',

                 side = 'right',
                 color = 'black',
                 content = 'close',

                 onclick = function()
                     close()
                 end
             },
             {
                 Button, key = 'back',

                 side = 'left',
                 color = 'white',
                 content = 'back',
                 w = measure('close'),

                 onclick = function()
                     back()
                 end
             }
        }, body = body}
    }
end

function get_time()
    return date("%H:%M")
end

function init()
    mask_color(0)

    menu = Menu:new({ time = get_time() })
    nom = menu:nom():use('cursor')

    -- Pausa todas as apps que eestão rodando
    for _, pid in ipairs(env.running) do
        pause_app(pid)
    end
end

function draw()
    if not visible then
        return
    end

    nom:draw()
end

function close()
    -- Avoid redrawing
    visible = false

    for _, pid in ipairs(env.running) do
        resume_app(pid)
    end

    stop_app(env.app.pid)
    stop_app(0)
end

function back()
    -- Avoid redrawing
    visible = false

    for _, pid in ipairs(env.running) do
        resume_app(pid)
    end

    stop_app(0)
end

function update(dt)
    if time()%30 == 0 then
        menu:set_state { time = get_time() }
    end

    if button_down(BLACK) then
        close()
    end

    if button_down(WHITE) then
        back()
    end

    nom:update(dt)
end
