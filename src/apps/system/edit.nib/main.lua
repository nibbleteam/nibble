env.menu = {
  'Nibble Edit',
  'v0.1.1',
  '',
  'by Uberoverlord'
}

require "lang.timeout"

require "nibui.Neact"
local NOM = require "nibui.NOM"
local Widget = require "nibui.Widget"
local Easing = require "nibui.Easing"
local find_app = require "path.find_app"

local found_apps = find_app((env.params and env.params[2]) or "")

local app = found_apps[1] or { name = "<NO APP>", path = "", entrypoint = "" }

-- Constants
local menu_height = 12

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

local filetypes = {
  ["code.nib"] = "entrypoint",
  ["sprite.nib"] = "spritesheet"
}

local editor_search_path = "apps/system/editors/"

local notification_time = 2

-- Notification queue
local notifications = {
  {
    content = "Nibble v0.2.0",
  }
}

local current_notification_timeout_id = nil
local notification_removing = false

-- Get all editors
local editor_paths = list_directory(editor_search_path)
local editor_buttons = {}

local button_x = icon_offset
local button_counter = 0

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
      button_x = (#icon_map+button_counter)*(icon_width+icon_gap)+icon_offset
      button_counter += 1
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
  end
end

local buttons_width = #editor_buttons*(icon_width+icon_gap)+2*icon_offset

local Edit = Neact.Component:new()

function Edit:new(props)
  return new(Edit, {
               props = props,
               state = {
                 menu = {
                   color = 7,
                 }
               }
  })
end

function Edit:render(state, props)
  return {
    x = NOM.left,  y = NOM.top,
    w = NOM.width, h = NOM.height,

    -- Menu
    {
      x = NOM.left, y = NOM.top,
      w = NOM.width, h = menu_height,
      background = state.menu.color,

      -- Highlight
      {
        y = NOM.bottom-1, h = 1,

        background = 15,
      },

      -- A "Run" button
      {
        x = NOM.left,
        y = NOM.top-2,
        w = 16, h = 16,

        background = { 0, 10 },

        onpress = function(self)
          -- Press the button
          self.background = { 1, 10 }
        end,

        onclick = function(self)
          -- Release the button
          self.background = { 0, 10 }

          local child = start_app(app.path, {})

          if child then
            -- Wait for child to exit
            pause_app(env.pid, child)
            pause_app(self.parent.parent:find("taskbar").running)

            -- Disable the mouse
            mouse_cursor(0, 0, 0, 0)
          end
        end,

        onenter = function(self)
          self.document:set_cursor("pointer")
        end,

        onleave = function(self)
          -- Release the button
          self.background = { 0, 10 }

          self.document:set_cursor("default")
        end,
      },

    },

    -- Background when no apps are running
    {
      x = NOM.left,  y = NOM.top+menu_height,
      w = NOM.width, h = NOM.height-taskbar_height-menu_height,
      id = "editor",

      draw = function(self)
        if self.dirty and not self.parent:find("taskbar").selected then
          Widget.draw(self)

          local side = 16
          local colors = { 16, 1 }

          -- Draw a checkers pattern
          for y=self.y,self.h+side,side do
            for x=self.x,self.w+side,side do
              fill_rect(x, y, side, side, colors[math.floor(x/side+y/side) % 2 + 1])
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
            widget.pid = start_app(id, {
              x = 0, y = menu_height,
              width=env.width,
              height=env.height-taskbar_height-menu_height,

              params = { id, app[filetypes[id:sub(editor_search_path:len()+1)]] or app.path },

              taskbar = env.pid,
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

      -- Notification Popup
      {
        id = "notification",

        x = NOM.right, w = 0,
        y = NOM.top+4, h = taskbar_height-6,

        {
          y = NOM.top+1,

          radius = 2,

          clip_to = 0,

          background = 1,
        },

        {
          id = "notification_content",

          radius = 2,

          background = 6,
        },

        {
          h = 1,
          x = NOM.left+1, w = NOM.width-2,

          background = 9,
        }
      },

      {
        padding_top = 1,
        content = app.name,
      },

      unwrap(editor_buttons)
    }
  }
end

local edit_app = Edit:new({})

-- UI
local ui = edit_app:nom():use('cursor')

function init()
  show_next_notification()
end

function draw()
  ui:draw()
end

function update(dt)
  ui:update(dt)

  local message

  repeat
    message = receive_message()

    if type(message) == "table" and message.kind == "notification" then
      push(notifications, {
             content = message.content or ""
      })

      show_next_notification()
    end

    if type(message) == "table" and message.app_stopped then
      resume_app(ui:find("#taskbar").running)
    end
  until message == nil

  run_timeouts(dt)
end

function show_next_notification()
  if current_notification_timeout_id then
    clear_timeout(current_notification_timeout_id)

    if not notification_removing then
      notification_removing = true

      ui:find("#notification").x = { NOM.right, 0.1, Easing.InOutCubic }

      current_notification_timeout_id = set_timeout(0.1, function()
        current_notification_timeout_id = nil
        notification_removing = false
        show_next_notification()
      end)

      return
    else
      while #notifications > 1 do
        shift(notifications)
      end
    end
  end

  local notification = shift(notifications)

  if notification then
    local text = notification.content

    local main_w = ui:find("#notification")
    local content_w = ui:find("#notification_content")

    local width = measure(text)+8

    content_w.content = text
    main_w.w = width
    main_w.x = { NOM.right-width-2, 0.3, Easing.OutCubic }

    current_notification_timeout_id = set_timeout(notification_time, function()
      main_w.x = { NOM.right, 0.3, Easing.InOutCubic }
      notification_removing = true

      current_notification_timeout_id = set_timeout(0.4, function()
        current_notification_timeout_id = nil
        notification_removing = false
        show_next_notification()
      end)
    end)
  end
end
