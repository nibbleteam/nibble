local NOM = require 'nibui.NOM'
local OperatorGraph = Neact.Component:new()

local Operator = require 'ui.Operator'

function OperatorGraph:new(props)
  return new(OperatorGraph, {
    props = props,
    state = {}
  })
end

function OperatorGraph:render(state)
  return {
    x = NOM.left, y = NOM.top,
    w = NOM.width, h = NOM.height,
    background = 3,

    {Operator,
      id = 'OP1',
      x = NOM.left,
      y = NOM.top},
    {Operator,
      id = 'OP2',
      x = NOM.left+2,
      y = NOM.top+60},
    {Operator,
      id = 'OP3',
      x = NOM.left+4,
      y = NOM.top+120},
    {Operator,
      id = 'OP4',
      x = NOM.left+6,
      y = NOM.top+180},
  }
end

return OperatorGraph