require "nibui.Neact"

local NOM = require "nibui.NOM"

local MenuItem = Neact.Component:new()

function MenuItem:new(props)
  return new(MenuItem, {
               props = props,
               state = {
                 open = nil
               }
  })
end

function MenuItem:render(state, props)
  local line_height = 12
  local menu_padding = 6
  local w = 0
  local h = props.item.items and #props.item.items*line_height or 0

  if props.item.items then
    for _, item in ipairs(props.item.items) do
      local text_w = measure(item.name)

      if text_w > w then
        w = text_w
      end
    end
  end

  -- Account for borders
  h += 4+menu_padding*2
  w += 2+menu_padding*2

  return {
    x = props.x, y = props.y, w = props.w, h = props.h,

    content = (not props.item.icon) and props.item.name,
    background = props.item.icon or 0,

    onclick = props.item.onclick or nil,

    padding_top = 0,

    cmap = state.open and {
      { 15, 15 },
      { 7, 16 },
      { 0, 16 }
    } or {
      { 15, 16 },
      { 7, 0 },
      { 0, 0 }
    },

    onenter = function(self)
      self.document:set_cursor("pointer")
    end,

    onleave = function(self)
      self.document:set_cursor("default")
    end,

    onpress = function(self)
      self.padding_top = 1
    end,

    onclick = function(w)
      w.padding_top = 0

      if props.item.onclick then
        props.item.onclick(w)
      else
        -- Pause the current app
        props.pause()

        self:set_state { open = true }
      end
    end,

    state.open and {
      x = NOM.left,
      y = NOM.top+NOM.height,
      w = w, h = h,

      clip_to = 0,

      background = props.color,
      border_color = 15,
      border_size = 1,
      radius = 2,

      onleave = function()
        props.resume()
        self:set_state { open = false }
      end,

      {
        x = NOM.left+1, y = NOM.bottom-3,
        h = 2, w = NOM.width-2,

        background = props.secondary_color,
      },

      NOM.map(props.item.items or {}, function(item, i)
                return {
                  x = NOM.left+menu_padding,
                  y = NOM.top+(i-1)*line_height+menu_padding,
                  h = line_height,
                  w = NOM.width-2*menu_padding,
                  content = item.name
                }
      end)
    } or nil
  }
end

return MenuItem
