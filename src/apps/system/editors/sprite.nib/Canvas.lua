local NOM = require 'nibui.NOM'
local Widget = require 'nibui.Widget'

local Canvas = Neact.Component:new()

local ALPHA_SIZE = 16

function Canvas:new(props)
  return new(Canvas, {
               props = props,
               state = {
                 cursor_x = 0, cursor_y = 0,
                 show_cursor = false,
               }
  })
end

function Canvas:pick_color(x, y)
  self.props.onpickcolor(self.props.sprite:get_pixel(x, y))
end

function Canvas:update_crosshair()
  local img = {
    { 59+24, 80 },
    { 59+24, 81 },
    { 59+24, 83 },
    { 59+24, 85 },
    { 59+24, 86 },
    { 56+24, 83 },
    { 57+24, 83 },
    { 61+24, 83 },
    { 62+24, 83 },
  }

  local sx, sy = 59-1+24, 83-1
  local px, py = mouse_position()

  for _, pix in ipairs(img) do
    local c = get_pixel(px+pix[1]-sx, py+pix[2]-sy)%16

    put_sheet_pixel(pix[1], pix[2], (c <= 4) and 15 or 1)
  end
end

function Canvas:render(state, props)
  props.scale = props.scale < 1 and 1 or props.scale

  local w, h = props.sprite.width*props.scale, props.sprite.height*props.scale

  return {
    x = NOM.left+(NOM.width-w)/2+props.offset_x,
    y = NOM.top+(NOM.height-h)/2+props.offset_y,
    w = w+2, h = h+2,

    background = 8,
    border_size = 1,
    border_color = 1,

    clip_to = 1,

    draw_checkboard = function(self)
      local x, y, w, h = self.x+1, self.y+1, self.w-2, self.h-2

      local side = ALPHA_SIZE*props.scale
      local colors = { 10, 8 }

      -- Draw a checkers pattern
      for iy=y,y+h-1,side do
        for ix=x,x+w-1,side do
          fill_rect(ix, iy, side, side, colors[math.floor(((ix-x)+(iy-y))/side) % 2 + 1])
        end
      end
    end,

    draw_cursor = function(self)
      if state.show_cursor then
        fill_rect(self.x+state.cursor_x*props.scale+1,
                  self.y+state.cursor_y*props.scale+1,
                  props.scale,
                  props.scale,
                  props.color-1)
      end
    end,

    draw_sprite = function(self, spr)
      local data = spr.data
      local w, h = spr.width, spr.height

      -- How much is hidden on the top/left
      local start_x = math.floor(math.max(0, self.parent.x-self.x)/props.scale)
      local start_y = math.floor(math.max(0, self.parent.y-self.y)/props.scale)
      -- How much is visible on the screen
      local end_x = start_x+math.floor(self.parent.w/props.scale)
      local end_y = start_y+math.floor(self.parent.h/props.scale)

      for y=start_y,end_y+1 do
        for x=start_x,end_x+1 do
          local c = data[y*w+x] or spr.solid

          if c and c:byte() then
            fill_rect(self.x+1+x*props.scale, self.y+1+y*props.scale,
                      props.scale, props.scale,
                      c:byte() + (props.palette-1)*16)
          end
        end
      end
    end,

    draw = function(self)
      if self.dirty then
        self.dirty = false

        clip(unwrap(Widget.clip_box(self, 1)))

        fill_rect(self.x, self.y, self.w, self.h, self.border_color)

        self:draw_checkboard()

        self:draw_sprite(props.sprite)
        self:draw_sprite(props.preview)

        self:draw_cursor()
      end
    end,

    onenter = function(w)
      if not props.picker then
        self:update_crosshair()
        w.document:set_cursor("crosshair")
      end

      self:set_state({
          show_cursor = true
      })
    end,

    onleave = function(w)
      w.document:set_cursor("default")

      self:set_state({
          show_cursor = false
      })
    end,

    onpress = function(w, event)
      local nx = math.floor((event.x-w.x)/props.scale)
      local ny = math.floor((event.y-w.y)/props.scale)

      if props.picker then
        self:pick_color(nx, ny)
      else
        self.props.tool:press(props.preview, props.sprite, nx, ny, props.color-1)

        -- So we also redraw the zoom
        w.parent:set_dirty()
      end
    end,

    onclick = function(w, event)
      local nx = math.floor((event.x-w.x)/props.scale)
      local ny = math.floor((event.y-w.y)/props.scale)

      if props.picker then
        -- self:pick_color(nx, ny)
      else
        self.props.tool:release(props.sprite, nx, ny, props.color-1)

        -- So we also redraw the zoom
        w.parent:set_dirty()
      end
    end,

    onmove = function(w, event)
      if not props.picker and not props.dragging then
        self:update_crosshair()
        w.document:set_cursor("crosshair")
      end

      local nx = math.floor((event.x-w.x)/props.scale)
      local ny = math.floor((event.y-w.y)/props.scale)

      if event.drag then
        if props.picker then
          self:pick_color(nx, ny)
        else
          props.tool:move(props.sprite,
                          state.cursor_x, state.cursor_y,
                          nx, ny,
                          props.color-1)

          -- So we also redraw the zoom
          w.parent:set_dirty()
        end
      end

      self:set_state {
        cursor_x = nx,
        cursor_y = ny
      }

      -- So we also redraw the zoom
      w.parent:set_dirty()
    end,
  }
end

return Canvas
