require 'nibui.Neact'

local NOM = require 'nibui.NOM'
local Widget = require 'nibui.Widget'

local Dialog = Neact.Component:new()
Dialog.Header = Neact.Component:new()
Dialog.Body = Neact.Component:new()

function Dialog:new(props)
   return new(Dialog, {
                 props = props,
                 state = props,
   })
end

function Dialog:render(state, props)
   return {
      x = NOM.left+(NOM.width-props.w)/2, y = NOM.top+(NOM.height-props.h)/2,
      w = props.w, h = props.h,

      {
        x = NOM.left, y = NOM.top,
        w = NOM.width, h = NOM.height,

        radius = 4,
        background = 1,

        {Dialog.Header, children = props.header, h = 16, key = "a"},
        {Dialog.Body, children = props.body, h = NOM.height-16-3, y = 16, key = "b"}
      }
   }
end

function Dialog.Header:new(props)
   return new(Dialog.Header, {
                 props = props,
                 state = props
   })
end

function Dialog.Header:render(state, props)
   local roundness = 2
   local border = 1

   local desc = {
        x = NOM.left+border, y = NOM.top+border,
        w = NOM.width-border*2, h = state.h-border,

        background = 0,

        draw = function(self)
           local bg = 10

           if self.dirty then
               clip(self.x, self.y, self.w, self.h)

               fill_rect(self.x, self.y+roundness,
                       self.w, self.h-roundness,
                       bg)

               fill_rect(self.x+roundness, self.y,
                       self.w-roundness*2, roundness,
                       bg)

               fill_circ(self.x+roundness, self.y+roundness,
                       roundness,
                       bg)
               fill_circ(self.x+self.w-roundness-1, self.y+roundness,
                       roundness,
                       bg)
           end

           Widget.draw(self)

            --for _, child in ipairs(self.children) do
            --    child:draw()
            --end
        end,
   }

   for k, v in ipairs(props.children) do
      insert(desc, v)
   end

   return desc
end

function Dialog.Body:new(props)
   return new(Dialog.Body, {
                 props = props,
                 state = props
   })
end

function Dialog.Body:render(state, props)
   local border = 1

   local desc = {
        x = NOM.left+border, y = NOM.top+border+state.y,
        w = NOM.width-border*2, h = state.h-border,

        radius = 2,

        background = 3,
   }

   for k, v in ipairs(props.children) do
      insert(desc, v)
   end

   return desc
end

return Dialog
