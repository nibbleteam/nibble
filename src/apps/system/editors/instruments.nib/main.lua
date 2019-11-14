env.menu = {
  'Instruments',
  'Instrument Maker'
}

-- Facebook's React-like library
require 'nibui.Neact'

local OperatorGraph = require 'ui.OperatorGraph'

-- Similar to a browser's DOM, but for nibble
local nom = OperatorGraph:new({}):nom():use('cursor')

function init()
  channel(CH1)
  -- Frequências
  freqs(1.0, 2.0, 7.0, 2.0)

  -- Roteia
  route(OP2, OP1, 69/255)
  route(OP1, OUT, 99/255)
  route(OP3, OUT, 60/255)
  route(OP4, OP3, 75/255)
  route(OP4, OP4, 75/255)
end

function draw()
  nom:draw()
end

function update(dt)
  nom:update(dt)
end
