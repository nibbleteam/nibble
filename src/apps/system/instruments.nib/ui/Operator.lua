local NOM = require 'nibui.NOM'
local Operator = Neact.Component:new()

local Envelope = require 'uikit.Envelope'

function Operator:new(props)
  return new(Operator, {
    props = props,
    state = {}
  })
end

function Operator:render(state)
  local w, h = 100, 60
  local p = 4

  local x = self.props.x or NOM.left+(NOM.width-w)/2
  local y = self.props.y or NOM.top+(NOM.height-h)/2

  return {
    id = self.props.id,
    x = x,
    y = y,
    w = w,
    h = h,
    radius = 2,

    background = 6,

    {Envelope,
      ref = function(env) self.env = env end,
      w = w-2*p,
      h = h-2*p,
      x = x+p,
      y = y+p},
  }
end

return Operator