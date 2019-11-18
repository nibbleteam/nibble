env.menu = {
  'Sprite Editor',
  'v0.1.0',
  '',
  'by @felipeoltavares',
}

require 'nibui.Neact'

local NOM = require 'nibui.NOM'
local Widget = require 'nibui.Widget'

local Sprite = Neact.Component:new()

local Palette = require 'Palette'
local PaletteSelector = require 'PaletteSelector'
local Canvas = require 'Canvas'
local Bitmap = require 'Bitmap'

local RevisionHistory = require 'RevisionHistory'

local PencilTool = require 'PencilTool'
local LineTool = require 'LineTool'
local FillTool = require 'FillTool'
local EraserTool = require 'EraserTool'

local spacing = 2

local title_h = 10

local palette_width = 27
local palette_height = 77
local palette_border_color = 16

local toolbar_width = 16+2*spacing

local palette_selector_height = 80+2*spacing

local max_zoom = 12

local source_file = env.params[2]

local main_sheet = nil

local function sheet_data()
  local data = {}
  local sheet, w, h = load_sheet(source_file)
  local sheet_data = get_sheet_full(sheet, w, h)

  main_sheet = sheet

  for y=0,h-1 do
    for x=0,w-1 do
      local p = y*w+x;

      data[p] = sheet_data:sub(p+1, p+1)
    end
  end

  return w, h, data, 0
end

-- Mutable data

local main_sprite = Bitmap:new(sheet_data())

local history = RevisionHistory:new(main_sprite.weight, main_sprite.hidth, main_sprite)

local tools = {
  { 6, PencilTool:new(history), 98 },
  { 7, LineTool:new(history), 108 },
  { 8, FillTool:new(history), 102 },
  { 9, EraserTool:new(history), 101 }
}

function Sprite:new(props)
  return new(Sprite, {
               props = props,
               state = {
                 selected_color = 16,
                 selected_palette = 1,
                 sprite = main_sprite,
                 preview = Bitmap:new(main_sprite.width, main_sprite.height, {}),
                 zoom = 1,
                 dragging = false,
                 picker = false,

                 -- The first tool in the tools array
                 tool = tools[1][2],

                 canvas_offset_x = 0,
                 canvas_offset_y = 0,
               },

               -- Canvas offset at the start of the drag
               drag_start_x = nil,
               drag_start_y = nil,

               -- Mouse at the start of the drag
               mouse_start_x = 0,
               mouse_start_y = 0,

               prev_cursor = nil,

               -- To calculate deltas and send messages
               zoom = 1,
  })
end

function Sprite:zoom_at_cursor(zoom)
  local cz = self.state.zoom
  local cx = self.state.canvas_offset_x
  local cy = self.state.canvas_offset_y

  self:set_state({
      zoom = zoom,
      canvas_offset_x = cx*zoom/cz,
      canvas_offset_y = cy*zoom/cz
  })
end

function Sprite:render(state, props)
  if state.zoom > 0 and state.zoom ~= self.zoom then
    send_message(env.taskbar, {
                   kind = "notification",
                   content = "x"..tostring(state.zoom),
    })

    self.zoom = state.zoom
  end

  return {
    x = NOM.left, y = NOM.top,
    w = NOM.width, h = NOM.height,
    background = 14,

    onkeydown = function(w, key, mods)
      if key == 32 then
        self:set_state({
            dragging = true
        })

        if not (self.drag_start_x or self.drag_start_y) then
          self.drag_start_x = state.canvas_offset_x
          self.drag_start_y = state.canvas_offset_y

          self.mouse_start_x, self.mouse_start_y = mouse_position()

          self.prev_cursor = w.document.cursor.state
          w.document:set_cursor("hand")
        end
      end

      if key == 226 then
        if not state.picker then
          self:set_state({
              picker = true
          })

          self.prev_cursor = w.document.cursor.state
          w.document:set_cursor("picker")
        end
      end

      if key == 122 and bit.band(mods, CTRL) ~= 0 then
        -- Redo
        if bit.band(mods, SHIFT) ~= 0 then
          history:redo(state.sprite)
          w:set_dirty()

          send_message(env.taskbar, {
                        kind = "notification",
                        content = "Redo"
          })
        -- Undo
        else
          history:undo(state.sprite)
          w:set_dirty()

          send_message(env.taskbar, {
                        kind = "notification",
                        content = "Undo!"
          })
        end
      end

      -- Save
      if key == 115 and bit.band(mods, CTRL) ~= 0 then
        put_sheet_full(join(state.sprite.data, "", 0), main_sheet, state.sprite.width, state.sprite.height)

        save_sheet(source_file, main_sheet, state.sprite.width, state.sprite.height)

        send_message(env.taskbar, {
                       kind = "notification",
                       content = "Saved spritesheet!"
        })
      end

      local zoom_levels = { 49, 50, 51, 52, 53, 54, 55, 56 }

      for zoom, zoom_key in ipairs(zoom_levels) do
        if key == zoom_key then
          self:zoom_at_cursor(zoom)
        end
      end

      for _, tool in ipairs(tools) do
        if key == tool[3] then
          self:set_state({
              tool = tool[2]
          })

          send_message(env.taskbar, {
                         kind = "notification",
                         content = ""..tool[2].name,
          })
        end
      end

      -- terminal_print("Pressed", key)
    end,

    onkeyup = function(w, key, mods)
      if key == 32 then
        self:set_state({
            dragging = false
        })

        self.drag_start_x = nil
        self.drag_start_y = nil

        w.document:set_cursor(self.prev_cursor)
      end

      if key == 226 then
        self:set_state({
            picker = false
        })

        w.document:set_cursor(self.prev_cursor)
      end

      -- terminal_print("Released", key)
    end,

    onscroll = function(w, x, y)
      self:zoom_at_cursor(math.max(1, math.min(max_zoom, y+state.zoom)))
    end,

    -- Palette
    {
      Palette,

      x = NOM.left+spacing, y = NOM.top+spacing,
      w = palette_width-2*spacing, h = palette_height,

      border_color = palette_border_color,
      width = palette_width,
      height = palette_height,
      spacing = spacing,

      selected = state.selected_color,
      palette = state.selected_palette or 1,

      onchange = function(color)
        self:set_state({
            selected_color = color
        })
      end
    },

    -- Palette Selector
    {
      PaletteSelector,
     
      x = NOM.left+spacing, y = NOM.bottom-palette_selector_height-spacing,
      w = palette_width-2*spacing, h = palette_selector_height,

      spacing = spacing,

      selected = state.selected_palette,

      onchange = function(palette)
        self:set_state({
            selected_palette = palette
        })
      end
    },

    -- Drawing area
    {
      x = NOM.left+palette_width, y = NOM.top+spacing,
      w = NOM.width-palette_width-toolbar_width, h = NOM.height-2*spacing,

      border_color = 3,
      border_size = 1,

      radius = 2,

      background = 7,

      onmove = function(w, event)
        if state.dragging then
          self:set_state({
              canvas_offset_x = event.x-self.mouse_start_x+self.drag_start_x,
              canvas_offset_y = event.y-self.mouse_start_y+self.drag_start_y,
          })
        end
      end,

      -- Canvas
      {
        Canvas,

        color = state.selected_color,
        palette = state.selected_palette,
        sprite = state.sprite,
        preview = state.preview,
        tool = state.tool,
        scale = state.zoom,
        dragging = state.dragging,
        picker = state.picker,
        offset_x = state.canvas_offset_x,
        offset_y = state.canvas_offset_y,

        onpickcolor = function(c)
          self:set_state { selected_color = c+1 }
        end
      },

      {
        x = NOM.right-2*spacing-64, y = NOM.bottom-2*spacing-9,
        w = 64, h = 9,

        {
          x = NOM.left+9, w = NOM.width-18,

          background = 2,
          border_color = 1,
          border_size = 1,
          radius = 2,

          set_zoom = function(w, event)
            local p = (event.x-w.x)/w.w

            self:zoom_at_cursor(math.ceil(p*max_zoom))
          end,

          onpress = function(w, event)
            w:set_zoom(event)
          end,

          onmove = function(w, event)
            if event.drag then
              w:set_zoom(event)
            end
          end,

          -- Highlight
          {
            y = NOM.top+1, x = NOM.left+1,
            w = NOM.width-2, h = 1,
            background = 3,
          },
          {
            x = NOM.left+1,
            w = state.zoom/max_zoom*(NOM.width-2),
            y = NOM.top+1,
            h = NOM.height-2,

            background = 14,

            {
              h = 1,
              background = 15,
            }
          },
        },

        -- Zoom out
        {
          w = 8,
          h = 9,

          clip_to = 0,
          background = { 80, 0, 8, 9 },

          onclick = function()
            self:zoom_at_cursor(state.zoom-1)
          end,

          onenter = function(self)
            self.document:set_cursor("hand")
          end,

          onleave = function(self)
            self.document:set_cursor("default")
          end,
        },
        -- Zoom in
        {
          y = NOM.top,
          x = NOM.right-8,
          w = 8, h = 9,

          clip_to = 0,
          background = { 88, 0, 8, 9 },

          onclick = function()
            self:zoom_at_cursor(math.min(max_zoom, state.zoom+1))
          end,

          onenter = function(self)
            self.document:set_cursor("hand")
          end,

          onleave = function(self)
            self.document:set_cursor("default")
          end,
        },
      }
    },

    -- Toolbar
    {
      x = NOM.right-toolbar_width, y = NOM.top+spacing,
      w = toolbar_width, h = NOM.height-2*spacing,

      NOM.map(tools, function(tool, i)
          return {
            x = NOM.left+spacing, y = NOM.top+spacing+(16+spacing)*(i-1),
            w = 16, h = 16,

            background = { state.tool == tool[2] and 1 or 0, tool[1] },

            onclick = function(w)
              self:set_state {
                tool = tool[2]
              }

              send_message(env.taskbar, {
                             kind = "notification",
                             content = "Using "..tool[2].name,
              })
            end,
          }
      end)
    },
  }
end

local sprite_editor = Sprite:new({})
local nom = sprite_editor:nom():use('cursor')

nom.cursor["crosshair"] = {
  x = 56, y = 80,
  w = 8, h = 8,
  hx = 3, hy = 3,
}

nom.cursor["picker"] = {
  x = 72, y = 80,
  w = 8, h = 8,
  hx = 0, hy = 8,
}

nom.cursor["hand"] = {
  x = 64, y = 80,
  w = 8, h = 8,
}

send_message(env.taskbar, {
               kind = "notification",
               content = "Welcome! \7"
})

function draw()
  nom:draw()
end

function update(dt)
  nom:update(dt)

  local keys = read_keys()

  for i=1,#keys do
    local key = keys:sub(i, i)

    if key == " " then
    end
  end
end
