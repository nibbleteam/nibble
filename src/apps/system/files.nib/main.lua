require 'nibui.Neact'

local Folder = require 'Folder'

local nom = Folder:new({}):nom()

function draw()
  nom:draw()
end

function update(dt)
  nom:update(dt)
end