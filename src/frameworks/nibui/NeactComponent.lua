local NOM = require 'nibui.NOM'

local NeactComponent = {}

function NeactComponent:new()
  return new(NeactComponent, {
    is_neact_component = true
  })
end

function NeactComponent:_render()
    if self.render then
        local vnom = self:render()

        -- Iterate over the children
        for k, component in pairs(vnom) do
          if component.is_neact_component then

          end
        end
    end

    return NOM:new({})
end

return NeactComponent
