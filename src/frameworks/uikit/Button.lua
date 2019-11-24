require 'nibui.Neact'

local NOM = require 'nibui.NOM'
local Widget = require 'nibui.Widget'

local Click = require 'soundkit.Click'

local Button = Neact.Component:new()

function Button:new(props)
   return new(Button, {
                 props = props,
                 state = {
                    pressed = false
                 },
   })
end

function Button:render(state, props)
   local x, cmap, background = nil, nil, nil
   local w = props.w or measure(props.content)+4
   local pad = 2
   local padding_top = 0

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

   if state.pressed then
      background[2] += 16
      padding_top = 1
   end

   return {
      x = x, w = w, y = NOM.top+1, h = NOM.height-2,
      padding_top = padding_top,
      background = background,
      content = props.content,
      cmap = cmap,

      onenter = function(w)
         w.document:set_cursor("pointer")
      end,

      onleave = function(w)
         w.document:set_cursor("default")

         if state.pressed then
            self:set_state { pressed = false }
            Click.release()
         end
      end,

      onpress = function(w)
         self:set_state { pressed = true }
         Click.press()
      end,

      onclick = function(w)
         self:set_state { pressed = false }
         Click.release()

         props.onclick()
      end,
   }
end

return Button
