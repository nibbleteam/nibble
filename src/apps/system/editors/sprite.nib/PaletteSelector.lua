local NOM = require 'nibui.NOM'

local PaletteSelector = Neact.Component:new()

function PaletteSelector:new(props)
  return new(PaletteSelector, {
               props = props,
               state = {}
  })
end

function PaletteSelector:build_palette_names(state, props)
  local names = {}

  local line_height = 10

  local selected = props.selected

  for i=1,8 do
    push(names, {
           x = NOM.left+props.spacing, y = NOM.top+props.spacing+(i-1)*line_height,
           w = NOM.width-2*props.spacing, h = line_height,

           background = (selected == i) and 3 or 0,
           border_color = (selected == i) and 1 or 0,
           border_size = 1,

           radius = 2,

           content = "#"..tostring(i),

           onclick = function()
             props.onchange(i)
           end
    })
  end

  return names
end

function PaletteSelector:render(state, props)
  return {
    x = props.x, y = props.y,
    w = props.w, h = props.h,

    border_color = 3,
    border_size = 1,

    radius = 2,

    background = 7,

    onenter = function(self)
      self.document:set_cursor("hand")
    end,

    onleave = function(self)
      self.document:set_cursor("default")
    end,

    unwrap(self:build_palette_names(state, props))
  }
end

return PaletteSelector
