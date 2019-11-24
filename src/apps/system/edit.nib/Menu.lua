require "nibui.Neact"

local NOM = require "nibui.NOM"

local Menu = Neact.Component:new()

local MenuItem = require "MenuItem"

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
    icon = { 0, 160, 16, 16 },
    onclick = props.run_app,
  }

  local items = copy(props.items)
  insert(items, run_item)

  local menu = {
    x = NOM.left, y = NOM.top,
    w = NOM.width, h = props.h,
    background = props.color,

    border = 2,

    NOM.map(items, function(item, i)
              local x = last_x
              local w = item.icon and item_width or measure(item.name)

              last_x += w+item_gap

              return {
                MenuItem, key = item.name,
               
                x = NOM.left+x,  y = NOM.top+1,
                w = w, h = NOM.height-2,

                color = props.color,
                secondary_color = props.secondary_color,

                item = item,

                pause = props.pause, resume = props.resume,
              }
    end)
  }

  return menu
end

return Menu
