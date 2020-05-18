local NOM = require 'nibui.NOM'
local Widget = require 'nibui.Widget'

local FloatingToolbox = Neact.Component:new()

function FloatingToolbox:new(props)
  return new(FloatingToolbox, {
               props = props,
               state = {
                 offset_x = 0,
                 offset_y = 0,
               },

               drag_start_x = 0, drag_start_y = 0,
               mouse_start_x = 0, mouse_start_y = 0,
  })
end

function FloatingToolbox:render(state, props)
  return {
    x = NOM.left+props.offset_x,
    y = NOM.top+props.offset_y,
    w = 21, h = 77,

    background = 7,

    {
      x = NOM.left+1, y = NOM.top,
      w = NOM.width-1, h = NOM.height-1,

      background = 14,

      -- Handle
      {
        x = NOM.left, y = NOM.top,
        w = NOM.width, h = 6,

        background = 14,

        { x = NOM.left+4, y = NOM.top+1, w = NOM.width-8, h = 1, background = 9 },
        { x = NOM.left+4, y = NOM.top+3, w = NOM.width-8, h = 1, background = 9 },

        onpress = function(w, event)
          props.ongrab(w)
        end,
      },

      -- Bottom line
      {
        x = NOM.left, y = NOM.bottom-1,
        w = NOM.width, h = 1,

        background = 9,
      }
    },
  }
end

return FloatingToolbox
