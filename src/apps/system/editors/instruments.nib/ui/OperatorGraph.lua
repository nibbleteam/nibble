local NOM = require 'nibui.NOM'
local Widget = require 'nibui.Widget'
local OperatorGraph = Neact.Component:new()

local Operator = require 'ui.Operator'

function OperatorGraph:new(props)
  return new(OperatorGraph, {
    props = props,
    state = {},
    op = {},
  })
end

function OperatorGraph:render(state)
  local w, h = 160, 100
  local sw, sh = (400-2*w)/3, (240-2*h)/3

  return {
    x = NOM.left, y = NOM.top,
    w = NOM.width, h = NOM.height,
    background = 3,

    {Operator, ref=function(op) self.op[1] = op end,
      id = 'OP1',
      x = NOM.left+sw,
      y = NOM.top+sh,
      w = w, h = h},
    {Operator, ref=function(op) self.op[2] = op end,
      id = 'OP2',
      x = NOM.left+w+sw*2,
      y = NOM.top+sh,
      w = w, h = h},
    {Operator, ref=function(op) self.op[3] = op end,
      id = 'OP3',
      x = NOM.left+sw,
      y = NOM.top+h+2*sh,
      w = w, h = h},
    {Operator, ref=function(op) self.op[4] = op end,
      id = 'OP4',
      x = NOM.left+w+2*sw,
      y = NOM.top+h+2*sh,
      w = w, h = h},

    update = function(w, dt)
      Widget.update(w, dt)

      local op_map = { OP1, OP2, OP3, OP4 }
      for i, op in ipairs(self.op) do
        local adsr = op:adsr()

        envelope(op_map[i], 0, 1, adsr[1], adsr[2], adsr[3], adsr[4], 0)
      end

      if button_press(RED) then
        noteon(48, 255)
      end
    end
  }
end

return OperatorGraph
