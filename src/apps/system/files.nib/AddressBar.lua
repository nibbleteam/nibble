local NOM = require 'nibui.NOM'

local AddressBar = Neact.Component:new()

function AddressBar:new(props)
  return new(AddressBar, {
    props = props,
    state = {}
  })
end

function AddressBar:render(props, state)
  return {
    x = NOM.left, y = NOM.top,
    w = NOM.width, h = 16,

    background = 8,
  }
end

return AddressBar