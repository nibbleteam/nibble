local NOM = require 'nibui.NOM'
local Widget = require 'nibui.Widget'

local FloatingToolbox = Neact.Component:new()

function FloatingToolbox:new(props)
  return new(FloatingToolbox, {
               props = props,
               state = {}
  })
end

function FloatingToolbox:render(state, props)
  return {
    x = NOM.left, y = NOM.top,
    w = 0, h = 0,

    background = 6,
  }
end

return FloatingToolbox
