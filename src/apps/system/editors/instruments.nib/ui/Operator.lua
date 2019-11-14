local NOM = require 'nibui.NOM'
local Operator = Neact.Component:new()

local Envelope = require 'uikit.Envelope'

function Operator:new(props)
  return new(Operator, {
    props = props,
    state = {}
  })
end

function Operator:adsr()
  return {
    self.env:attack(),
    self.env:decay(),
    self.env:sustain(),
    self.env:release(),
  }
end

function Operator:render(state, props)
  local w, h = props.w, props.h
  local p = 6

  return {
    id = self.props.id,
    x = props.x,
    y = props.y,
    w = w,
    h = h,
    radius = 4,

    background = 2,

    {Envelope,
      ref = function(env) self.env = env end,
      w = w-2*p,
      h = h-2*p,
      x = NOM.left+p,
      y = NOM.top+p},
  }
end

return Operator
