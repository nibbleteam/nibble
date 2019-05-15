local d = require('nibui.NOM').dynamic

local Component = inherit(Neact.Component)

function Component:new(props)
    return new(Component, {
        state = {
            color = 8
        }
    }, props)
end

function Component:render(state, props)
    return {
        --x = dynamic 'parent.x', y = dynamic 'parent.y',
        --w = dynamic 'parent.w', h = dynamic 'parent.h',
        x = d'^''x', y = d'^''y',
        w = d'^''w', h = d'^''h',
        background = state.color,

        onclick = function() self:onclick() end,

        Component,
    }
end

function Component:onclick()
    self:set_state({
        color = 10
    })
end

