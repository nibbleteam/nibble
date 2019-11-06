local NOM = require 'nibui.NOM'

local nom = NOM:new({
  x = NOM.left, y = NOM.top,
  w = NOM.width, h = NOM.height,
  background = 6
})

function draw()
  nom:draw()
end

function update(dt)
  nom:update(dt)
end