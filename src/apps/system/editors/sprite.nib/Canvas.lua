local NOM = require 'nibui.NOM'
local Widget = require 'nibui.Widget'

local Canvas = Neact.Component:new()

local ALPHA_SIZE = 16

-- Crops a AABB to screen boundaries
local function crop_to_screen(x, y, w, h,
                             sx, sy, sw, sh)
  return math.max(x, sx), math.max(y, sy), math.min(x+w, sx+sw), math.min(y+h, sy+sh)
end

-- Converts screen coords to canvas coords, given the origin and scale of the canvas
local function screen_to_canvas(ox, oy,
                                sx, sy,
                                x1, y1, x2, y2)
  local x, y = math.floor((x1-math.floor(ox))/sx), math.floor((y1-math.floor(oy))/sy)

  return x, y, x+math.ceil((x2-x1)/sx), y+math.ceil((y2-y1)/sy)
end

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
  props.scale = props.scale < 1 and 1 or math.floor(props.scale)

  local w, h = props.sprite.width*props.scale, props.sprite.height*props.scale

  return {
    x = NOM.left+(NOM.width-w)/2+props.offset_x,
    y = NOM.top+(NOM.height-h)/2+props.offset_y,
    w = w, h = h,

    background = 8,

    draw_checkboard = function(self)
      local x, y, w, h = math.floor(self.x), math.floor(self.y), self.w, self.h

      local side = ALPHA_SIZE*props.scale
      local colors = { 10, 8 }

      -- Draw a checkers pattern
      for iy=y,y+h,side do
        for ix=x,x+w,side do
          fill_rect(ix, iy, side, side, colors[math.floor(((ix-x)+(iy-y))/side) % 2 + 1])
        end
      end
    end,

    draw_cursor = function(self)
      if state.show_cursor then
        fill_rect(math.floor(self.x)+state.cursor_x*props.scale,
                  math.floor(self.y)+state.cursor_y*props.scale,
                  props.scale,
                  props.scale,
                  props.color-1)
      end
    end,

    draw_sprite = function(self, spr)
      local data = spr.data
      local w, h = spr.width, spr.height

      local start_x, start_y, end_x, end_y = screen_to_canvas(self.x, self.y, props.scale, props.scale,
                                                              crop_to_screen(self.x, self.y, self.w, self.h,
                                                                             self.parent.x, self.parent.y,
                                                                             self.parent.w, self.parent.h))

      for y=start_y,end_y-1 do
        for x=start_x,end_x-1 do
          local c = data[y*w+x] or spr.solid

          if c and c:byte() then
            fill_rect(math.floor(self.x)+x*props.scale,
                      math.floor(self.y)+y*props.scale,
                      props.scale, props.scale,
                      c:byte() + (props.palette-1)*16)
          end
        end
      end
    end,

    draw = function(self)
      if self.dirty then
        self.dirty = false

        clip(unwrap(Widget.clip_box(self, 0)))

        self:draw_checkboard()

        self:draw_sprite(props.sprite)
        self:draw_sprite(props.preview)

        self:draw_cursor()
      end
    end,

    onenter = function(w)
      if props.dragging then
        return
      end

      if not props.picker then
        self:update_crosshair()
        w.document:set_cursor("crosshair")
      end

      self:set_state({
          show_cursor = true
      })
    end,

    onleave = function(w)
      if props.dragging then
        return
      end

      w.document:set_cursor("default")

      self:set_state({
          show_cursor = false
      })
    end,

    onpress = function(w, event)
      local nx = math.floor((event.x-math.floor(w.x))/props.scale)
      local ny = math.floor((event.y-math.floor(w.y))/props.scale)

      if props.dragging then
        return
      end

      if props.picker then
        self:pick_color(nx, ny)
      else
        self.props.tool:press(props.preview, props.sprite, nx, ny, props.color-1)

        -- So we also redraw the zoom
        w.parent:set_dirty()
      end
    end,

    onclick = function(w, event)
      local nx = math.floor((event.x-math.floor(w.x))/props.scale)
      local ny = math.floor((event.y-math.floor(w.y))/props.scale)

      if props.dragging then
        return
      end

      if props.picker then
        -- self:pick_color(nx, ny)
      else
        self.props.tool:release(props.sprite, nx, ny, props.color-1)

        -- So we also redraw the zoom
        w.parent:set_dirty()
      end
    end,

    onmove = function(w, event)
      if props.dragging then
        return
      end

      if not props.picker and not props.dragging then
        self:update_crosshair()
        w.document:set_cursor("crosshair")
      end

      local nx = math.floor((event.x-math.floor(w.x))/props.scale)
      local ny = math.floor((event.y-math.floor(w.y))/props.scale)

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
