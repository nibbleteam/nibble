require 'nibui.Neact'

local NOM = require 'nibui.NOM'
local Widget = require 'nibui.Widget'

local Button = Neact.Component:new()

function Button:new(props)
   return new(Button, {
                 props = props,
                 state = props,
   })
end

function Button:render(state, props)
   local x, cmap, background = nil, nil, nil
   local w = props.w or measure(props.content)+4
   local pad = 2

   if props.side == 'right' then
      x = NOM.right-w-pad
   else
      x = NOM.left+pad
   end

   if props.color == 'white' then
      background = {0, 96, 16, 16, 1, 15, 1, 14}
      cmap = {
         {15, 2},
         {7, 10},
      }
   else
      background = {16, 96, 16, 16, 1, 15, 1, 14}
      cmap = {
         {15, 15},
         {7, 7},
      }
   end


   return {
      x = x, w = w, y = NOM.top+1, h = NOM.height-2,
      background = background,
      content = props.content,
      cmap = cmap,
   }
end

return Button
