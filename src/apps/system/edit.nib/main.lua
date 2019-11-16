env.menu = {
  'Nibble Edit',
  'v0.0.1',
  '',
  'by Uberoverlord'
}

local NOM = require "nibui.NOM"
local Widget = require "nibui.Widget"

-- Constants
local taskbar_height = 18
local taskbar_background_color = 3
local taskbar_highlight_color = 7
local taskbar_silhouette_color = 1

local icon_width = 16
local icon_height = 16
local icon_gap = 0
local icon_jump = 2
local icon_offset = 2

local icon_map = {
  ["music.nib"] = {
    sprite_y = 6,
    button_position = 3
  },
  ["code.nib"] = {
    sprite_y = 7,
    button_position = 1,
  },
  ["sprite.nib"] = {
    sprite_y = 8,
    button_position = 2,
  },
  ["map.nib"] = {
    sprite_y = 9,
    button_position = 4,
  },
}
local editor_search_path = "apps/system/editors/"

-- Get all editors
local editor_paths = list_directory(editor_search_path)
local editor_buttons = {}

local button_x = icon_offset

-- Prepare buttons for editors
for _, path in ipairs(editor_paths) do
  -- If the name does not start with a .
  if not path:match("[/\\]%..*") then
    local icon_info = icon_map[path:sub(editor_search_path:len()+1)]
    local background

    -- The icon has a custom position and sprite
    if icon_info then
      background = { 2, icon_info.sprite_y }
      button_x = (icon_info.button_position-1)*(icon_width+icon_gap)+icon_offset
    else
      background = { 2, 10 }
    end

    insert(editor_buttons,{
      x = NOM.left+button_x, y = NOM.top+icon_jump-1,
      w = icon_width, h = icon_height,
      background = background,
      id = path,
      pid = nil,

      onclick = function(self)
        self.parent:select(self.id, self)
      end,

      onenter = function(self)
        self.document:set_cursor("pointer")
      end,

      onleave = function(self)
        self.document:set_cursor("default")
      end,
    })

    button_x += icon_width+icon_gap
  end
end

-- UI
local ui = NOM:new({
  x = NOM.left,  y = NOM.top,
  w = NOM.width, h = NOM.height,

  -- Background when no apps are running
  {
    x = NOM.left,  y = NOM.top,
    w = NOM.width, h = NOM.height-taskbar_height,
    id = "editor",

    draw = function(self)
      if self.dirty and not self.parent:find("taskbar").selected then
        Widget.draw(self)

        local side = 16
        local colors = { 16, 1 }

        -- Draw a checkers pattern
        for y=self.y,self.h,side do
          for x=self.x,self.w,side do
            fill_rect(x, y, side, side, colors[(x/side+y/side) % 2 + 1])
          end
        end
      end
    end
  },

  -- The taskbar itself
  {
    id = "taskbar",

    x = NOM.left,  y = NOM.bottom-taskbar_height,
    w = NOM.width, h = taskbar_height,
    background = taskbar_background_color,

    selected = nil,
    running = nil,

    select = function(self, id, widget)
      if self.selected ~= id then
        -- Move the icon up
        widget.y -= icon_jump
        -- and select the bright background
        widget.background[1] -= 2

        -- If there was an app running, pause it
        if self.selected ~= nil then
          local prev_widget = self:find(self.selected)
          -- and also move its icon down
          prev_widget.y += icon_jump
          -- and select the dark background
          prev_widget.background[1] += 2

          pause_app(self.running)
        end

        -- If this app has a running process
        if widget.pid then
          -- just resume it
          resume_app(widget.pid)

          self.running = widget.pid
        else
          -- otherwise start it from the ground up
          widget.pid = start_app(id,{
            x=0,y=0,
            width=env.width,
            height=env.height-taskbar_height,

            params = env.params
          }, true)

          self.running = widget.pid
        end

        -- Mark as selected
        self.selected = id
      end
    end,

    -- A little highlight line
    {
      x = NOM.left, y = NOM.top,
      w = NOM.width, h = 1,

      background = taskbar_highlight_color
    },
    -- A little silhouette line
    {
      x = NOM.left, y = NOM.top+1,
      w = NOM.width, h = 1,

      background = taskbar_silhouette_color
    },

    -- A "reload" button
    -- {
    --   x = NOM.right-16, y = NOM.bottom-taskbar_height+8,
    --   w = 16, h = 16,

    --   background = 9,

    --   content = "R",

    --   onclick = function(self)
    --     local taskbar = self.parent:find("taskbar")

    --     if taskbar.selected then
    --       local widget = self.parent:find(taskbar.selected)

    --       -- Disable grouping so we don't kill ourselves too
    --       stop_app(widget.pid, true)

    --       widget.pid = start_app(taskbar.selected, {
    --         x=0,y=0,
    --         width=env.width,
    --         height=env.height-taskbar_height,

    --         params = env.params
    --       }, true)

    --       taskbar.running = widget.pid
    --     end
    --   end
    -- },

    unwrap(editor_buttons)
  }

}):use('cursor')

function draw()
  ui:draw()
end

function update(dt)
  ui:update(dt)
end
