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

local Menu = require "Menu"

local found_apps = find_app((env.params and env.params[2]) or "")

local editing_app = found_apps[1] or { name = "<NO APP>", path = "", entrypoint = "" }

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
local editor_apps = {}

-- Prepare editor apps
for _, path in ipairs(editor_paths) do
  -- If the name does not start with a .
  if not path:match("[/\\]%..*") then
    local icon_info = icon_map[path:sub(editor_search_path:len()+1)]
    local sprite
    local position = 9

    -- The icon has a custom position and sprite
    if icon_info then
      sprite = { 2, icon_info.sprite_y }
      position = icon_info.button_position
    else
      sprite = { 2, 10 }
    end

    local pid = start_app(path, {
      -- Viewport
      x = 0, y = menu_height,
      width = env.width, height = env.height-taskbar_height-menu_height,

      -- Which file to edit
      params = { path, editing_app[filetypes[path:sub(editor_search_path:len()+1)]] or path },

      -- PID to send messages to
      taskbar = env.pid,
    }, true)

    pause_app(pid)

    insert(editor_apps, {
      position = position,
      sprite = sprite,
      path = path,
      pid = pid,

      menu = { color = 16, secondary_color = 15, items = {} }
    })

    sort(editor_apps, function(a, b)
           if a.position == b.position then
             -- Alphabetic order
             return a.path:byte() < b.path:byte()
           else
             return a.position < b.position
           end
    end)
  end
end

local buttons_width = #editor_apps*(icon_width+icon_gap)+2*icon_offset

local Edit = Neact.Component:new()

function Edit:new(props)
  return new(Edit, {
               props = props,
               state = {
                 menu = {
                   color = 3,
                   secondary_color = 7,

                   items = {}
                 },

                 apps = editor_apps,

                 selected = nil,
               }
  })
end

function Edit:resume()
  if self.state.selected then
    resume_app(self.state.apps[self.state.selected].pid)
  end
end

function Edit:pause()
  if self.state.selected then
    pause_app(self.state.apps[self.state.selected].pid)
  end
end

function Edit:select(i)
  -- Pause the previously running app
  if self.state.selected then
    local prev = self.state.apps[self.state.selected]

    if prev.pid then
      pause_app(prev.pid)
    end
  end

  -- Start/resume the clicked app
  local app = self.state.apps[i]

  if app.pid then
    resume_app(app.pid)
  else
    app.pid = start_app(app.path, {
      -- Viewport
      x = 0, y = menu_height,
      width = env.width, height = env.height-taskbar_height-menu_height,

      -- Which file to edit
      params = { app.path, editing_app[filetypes[app.path:sub(editor_search_path:len()+1)]] or app.path },

      -- PID to send messages to
      taskbar = env.pid,
    }, true)
  end

  -- Update the menu, without any transition
  self:set_state {
    menu = app.menu,
    apps = self.state.apps
  }

  -- Update the app, with a slight transition
  -- (in the up/down icon movement)
  self:set_state({
    selected = i,
  }, 0.05)
end

function Edit:set_menu(menu)
  if self.state.selected then
    local app = self.state.apps[self.state.selected]

    app.menu = {
      color = menu.color or 16,
      secondary_color = menu.secondary_color or 16,
      items = menu.items or {}
    }

    self:set_state {
      menu = app.menu,
      apps = self.state.apps
    }
  end
end

function Edit:render(state, props)
  return {
    x = NOM.left,  y = NOM.top,
    w = NOM.width, h = NOM.height,

    {Menu,
     h = menu_height,

     color = state.menu.color,
     secondary_color = state.menu.secondary_color,
     items = state.menu.items,

     run_app = function(self)
       local child = start_app(editing_app.path, {})

       if child then
         -- Wait for child to exit
         pause_app(env.pid, child)

         if state.selected then
           pause_app(state.apps[state.selected].pid)
         end

         -- Disable the mouse
         mouse_cursor(0, 0, 0, 0)
       end
     end,

     pause = function() self:pause() end,
     resume = function() self:resume() end,
    },

    -- Background when no apps are running
    {
      x = NOM.left,  y = NOM.top+menu_height,
      w = NOM.width, h = NOM.height-taskbar_height-menu_height,
      id = "editor",

      draw = function(self)
        if self.dirty and state.selected == nil then
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
        content = editing_app.name,
      },

      -- Generate app buttons
      NOM.map(state.apps, function(desc, i)
                return {
                  x = (i-1)*(icon_width+icon_gap)+icon_offset, y = NOM.top-1+(i == state.selected and 0 or icon_jump),
                  w = icon_width, h = icon_height,

                  background = { desc.sprite[1] + (i == state.selected and -2 or 0), desc.sprite[2] },

                  onclick = function(w)
                    self:select(i)
                  end,

                  onenter = function(w)
                    w.document:set_cursor("pointer")
                  end,

                  onleave = function(w)
                    w.document:set_cursor("default")
                  end,
                }
      end)
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
      edit_app:resume()
    end

    if type(message) == "table" and message.kind == "set_menu" then
      edit_app:set_menu(message.menu)
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
