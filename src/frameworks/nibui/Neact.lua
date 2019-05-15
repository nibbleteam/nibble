local Neact = {
  -- Stores class instances during the
  -- entire lifetime of the app
  instances = {}
}

Neact.Component = require 'nibui.NeactComponent'

return Neact
