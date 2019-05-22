require 'nibui.Neact'
local d = require('nibui.NOM').dynamic

local Component = Neact.Component:new()
local Button = Neact.Component:new()

function Component:new(props)
    return new(Component, {
        props = props,
        state = {
            buttons = {}
        }
    })
end

function Component:render(state, props)
    local list = {
        --x = dynamic 'parent.x', y = dynamic 'parent.y',
        --w = dynamic 'parent.w', h = dynamic 'parent.h',
        x = d'^''x', y = d'+'(d'^''y', 16),
        w = d'^''w', h = d'-'(d'^''h', 32),
        background = props.color,

        onclick = function() self:onclick() end,
        onleave = function() self:onleave() end,
    }

    for i, b in ipairs(state.buttons) do
        push(list, {Button, id=tostring(i), color = #state.buttons, offset = i*20})
    end

    return {
        x = d'^''x', y = d'^''y',
        w = d'^''w', h = d'^''h',
        background = 1,

        list
    }
end

function Component:onleave()
    pop(self.state.buttons)

    self:set_state(self.state)
end

function Component:onclick()
    push(self.state.buttons, 1)

    self:set_state(self.state)
end

function Button:new(props)
    return new(Button, {
        props = props,
        state = { color = props.color or 9 }
    })
end

function Button:render(state, props)
    return {
        --x = dynamic 'parent.x', y = dynamic 'parent.y',
        --w = dynamic 'parent.w', h = dynamic 'parent.h',
        x = d'+'(d'^''x', 16), y = d'+'(d'^''y', props.offset),
        w = d'-'(d'^''w', 32), h = 16,
        background = state.color,

        onclick = function() self:onclick() end,
    }
end

function Button:onclick()
    self:set_state({
        color = 12
    })
end

function str(v)
    return terminal_pretty.pformat(v)
end

function init()
    mask_color(0)

    nom = Component:new({ color = 8 }):nom():use('cursor')
end

function draw()
    nom:draw()
end

function update(dt)
    nom:update(dt)
end
