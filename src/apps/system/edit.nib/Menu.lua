require "nibui.Neact"

local NOM = require "nibui.NOM"

local Menu = Neact.Component:new()

function Menu:new(props)
  return new(Menu, {
               props = props,
               state = {}
  })
end

function Menu:render(state, props)
  local item_width = 16

  return {
    x = NOM.left, y = NOM.top,
    w = NOM.width, h = props.h,
    background = props.color,

    -- Highlight
    {
      y = NOM.bottom-1, h = 1,

      background = 15,
    },

    -- A "Run" button
    --{
    --  x = NOM.left,
    --  y = NOM.top-2,
    --  w = 16, h = 16,

    --  background = { 0, 10 },

    --  onpress = function(self)
    --    -- Press the button
    --    self.background = { 1, 10 }
    --  end,

    --  onclick = function(self)
    --    -- Release the button
    --    self.background = { 0, 10 }

    --    local child = start_app(app.path, {})

    --    if child then
    --      -- Wait for child to exit
    --      pause_app(env.pid, child)
    --      pause_app(self.parent.parent:find("taskbar").running)

    --      -- Disable the mouse
    --      mouse_cursor(0, 0, 0, 0)
    --    end
    --  end,

    --  onenter = function(self)
    --    self.document:set_cursor("pointer")
    --  end,

    --  onleave = function(self)
    --    -- Release the button
    --    self.background = { 0, 10 }

    --    self.document:set_cursor("default")
    --  end,
    --},

    NOM.map(props.items, function(item, i)
              return {
                x = (i-1)*item_width, w = item_width,

                background = math.random(16)
              }
    end)
  },
end

return Menu
