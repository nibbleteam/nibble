local NOM = require 'nibui.NOM'

local Palette = Neact.Component:new()

function Palette:new(props)
  return new(Palette, {
               props = props,
               state = {}
  })
end

function Palette:build_palette_colors(state, props)
  local colors = {}

  local col_w, col_h = 10, 10
  local x, y = props.spacing, props.spacing

  local bc = props.border_color

  local selected = props.selected

  for i=0,15 do
    push(colors, {
           id = "color "..tostring(i),

           x = NOM.left+x, y = NOM.top+y,
           w = col_w, h = col_h,

           border_size = (i == selected-1) and 2 or 1,
           border_color = bc,

           background = i+(props.palette-1)*16,

           onclick = function()
             props.onchange(i+1)
           end,
    })

    x += col_w-1

    if x > props.width-props.spacing*2-col_w then
      x = props.spacing
      y += col_h-1
    end
  end

  return colors
end

function Palette:render(state, props)
  return {
    id = "palette",

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

    unwrap(self:build_palette_colors(state, props))
  }
end

return Palette
