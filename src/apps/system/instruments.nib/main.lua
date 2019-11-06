env.menu = {
  'Instruments',
  'Instrument Maker'
}

-- Facebook's React-like library
require 'nibui.Neact'

local OperatorGraph = require 'ui.OperatorGraph'

-- Similar to a browser's DOM, but for nibble
local nom = OperatorGraph:new({}):nom():use('cursor')

function draw()
  nom:draw()
end

function update(dt)
  nom:update(dt)
end