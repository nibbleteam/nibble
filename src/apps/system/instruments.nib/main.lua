env.menu = {
  'Instruments',
  'Instrument Maker'
}

-- Facebook's React-like library
require 'nibui.Neact'

local Envelope = require 'uikit.Envelope'

-- Similar to a browser's DOM, but for nibble
local nom = Envelope:new({}):nom():use('cursor')

function draw()
  nom:draw()
end

function update(dt)
  nom:update(dt)
end