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
  local item_offset = 2
  local item_gap = 4
  local item_width = 16

  local last_x = item_offset

  local run_item = {
    name = "Run",
    icon = { 2, 161, 14, 12 },
    onclick = props.run_app,
  }

  local items = copy(props.items)
  insert(items, run_item)

  local menu = {
    x = NOM.left, y = NOM.top,
    w = NOM.width, h = props.h,
    background = props.color,

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

    NOM.map(items, function(item, i)
              local x = last_x
              local w = item.icon and item_width or measure(item.name)

              last_x += w+item_gap

              return {
                x = NOM.left+x, w = w,

                content = (not item.icon) and item.name,
                background = item.icon or 0,

                onclick = item.onclick or nil,

                onenter = function(self)
                  self.document:set_cursor("pointer")
                end,

                onleave = function(self)
                  self.document:set_cursor("default")
                end,
              }
    end)
  }

  return menu
end

return Menu
