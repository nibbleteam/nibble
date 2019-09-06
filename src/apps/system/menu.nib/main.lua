require 'nibui.Neact'
local NOM = require 'nibui.NOM'
local Dialog = require 'uikit.Dialog'
local Button = require 'uikit.Button'

local Menu = Neact.Component:new()

local menu, nom = nil, nil

function Menu:new(props)
    return new(Menu, {
                   state = props,
                   props = props
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
        background = 0,

        {Dialog, w = 160, h = 128, header = {
             {
                 x = NOM.left, y = NOM.top, w = NOM.width, h = NOM.height,
                 content = state.time
             },
             {
                 Button,
                 side = 'right',
                 color = 'black',
                 content = 'close'
             },
             {
                 Button,
                 side = 'left',
                 color = 'white',
                 content = 'back',
                 w = measure('close'),
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

    pause_app(env.app.pid)
end

function draw()
    nom:draw()
end

function update(dt)
    if time()%60 == 0 then
        menu:set_state({time = get_time() })
    end

    nom:update(dt)

    if button_down(BLACK) then
        stop_app(env.app.pid)
        stop_app(0)

        return
    end

    if button_down(WHITE) then
        resume_app(env.app.pid)
        stop_app(0)

        return
    end
end
