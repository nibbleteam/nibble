local NOM = require 'nibui.NOM'
local Widget = require 'nibui.Widget'

local Point = {}

function Point:new(x, y, direction, prev)
  return new(Point, {
    x = x or 0, y = y or 0,
    base_x = x or 0, base_y = y or 0,
    orig_x = x or 0, orig_y = y or 0,
    offset_x = 0, offset_y = 0,
    radius = 12,
    color = 9,
    selected = false, hover = false,
    direction = direction or 'x',
    prev = prev or nil
  })
end

function Point:draw(h)
  local en = self.selected or self.hover
  local circ_fn = en and circ or circ

  circ_fn(self.offset_x+self:get("x"),
          self.offset_y+self:get("y"),
          self.radius + (en and 2 or 0),
          self.color+1)

  local x1, x2, y1, y2 = 0, 0, h, 0

  if self.prev then
    x1, y1 = self.prev:get("x"), self.prev:get("y")
  end  
  
  x2, y2 = self:get("x"), self:get("y")

  x1 += self.offset_x
  x2 += self.offset_x
  y1 += self.offset_y
  y2 += self.offset_y

  line(x1, y1, x2, y2, self.color)
end

function Point:update(dt, ox, oy)
  self.offset_x = ox
  self.offset_y = oy
end

function Point:get(name)
  local v = self[name]

  if type(v) == 'function' then
    return v()
  else
    local d = name:sub(#name, #name)

    if self.prev and d == 'x' then
      v += self.prev:get(d)
    end

    return v
  end
end

function Point:mouse_move(event, drag_start)
  self.hover = self:inside(event.x, event.y)

  if drag_start then
    self.selected = self:inside_base(drag_start.x, drag_start.y)

    if self.selected and event.drag then
      for d in self.direction:gmatch '.' do
        self[d] = math.max(
          self["base_"..d]+event[d]-drag_start[d],
          0
        )
      end
    end
  else
    self.selected = nil
  end
end

function Point:mouse_released()
  self.base_x = self.x
  self.base_y = self.y
end

function Point:inside_base(x, y)
  local dx, dy = self.offset_x+self:get("base_x")-x, self.offset_y+self:get("base_y")-y
  
  return dx*dx+dy*dy <= self.radius*self.radius
end

function Point:inside(x, y)
  local dx, dy = self.offset_x+self:get("x")-x, self.offset_y+self:get("y")-y

  return dx*dx+dy*dy <= self.radius*self.radius
end

local Envelope = Neact.Component:new()

function Envelope:new(props)
  local envelope = new(Envelope, {
    props = props,
    state = {
      x = props.x or NOM.left,
      y = props.y or NOM.top,
      w = props.w or NOM.width,
      h = props.h or NOM.height,
      points = {}
    },
    click_start = nil,
  })

  local points = envelope.state.points

  local p0 = Point:new(0, 0, 'x')
  local p1 = Point:new(0, 0, 'xy', p0)
  local p2 = Point:new(0, 0, 'x', p1)

  push(points, p2)
  push(points, p1)
  push(points, p0)

  return envelope
end

function Envelope:attack()
  return math.max(math.min(
          self.state.points[3].x/self.w.w,
          1),
         0)
end

function Envelope:decay()
  return math.max(math.min(
          self.state.points[2].x/self.w.w,
          1),
         0)
end

function Envelope:sustain()
  return math.max(math.min(
          (self.w.h-self.state.points[2].y)/self.w.h,
          1),
         0)
end

function Envelope:release()
  return math.max(math.min(
          self.state.points[1].x/self.w.w,
          1),
         0)
end

function Envelope:render(state)
  return {
    ref = function(w) self.w = w end,
    x = state.x, y = state.y,
    w = state.w, h = state.h,

    background = 16,

    draw = function(w)
      if w.dirty then
        Widget.draw(w)

        state.points[1].y = w.h
      
        clip(w.x, w.y, w.w, w.h)
        for _, point in ipairs(state.points) do
          point:draw(w.h)
        end
        clip(0, 0, 400, 240)
      end
    end,

    onmove = function(w, event)
      for _, point in ipairs(state.points) do
        point:mouse_move(event, self.click_start)
      end

      point = state.points[3]

      if point:get("x") > w.w then
        point.x -= point:get("x")-w.w

        point.x = math.max(0, point.x)
      end

      return false
    end,

    onpress = function(w, event)
      self.click_start = copy(event)
    end,

    onclick = function(w, event)
      self.click_start = nil

      for _, point in ipairs(state.points) do
        point:mouse_released()
      end
    end,

    update = function(w, dt)
      Widget.update(w, dt)

      for _, point in ipairs(state.points) do
        point:update(dt, w.x, w.y)
      end
    end
  }
end

return Envelope
