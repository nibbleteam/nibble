local NOM = require 'nibui.NOM'
local AddressBar = require 'AddressBar'

local Folder = Neact.Component:new()

function Folder:new(props)
  return new(Folder, {
    props = props,
    state = {}
  })
end

function Folder:render(props, state)
  return {
    x = NOM.left, y = NOM.top,
    w = NOM.width, h = NOM.height,
    background = 9,

    {AddressBar}
  }
end

return Folder