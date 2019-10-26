local NOM = require 'nibui.NOM'
local Widget = require 'nibui.Widget'

local Point = {}

function Point:new(x, y, direction)
  return new(Point, {
    x = x or 0, y = or 0,
    radius = 8,
    selected = false,
    direction = direction
  })
end

function Point:draw()
  local circ_fn = self.selected and fill_circ or circ

  circ_fn(self.x, self.y, self.radius, 9)
end

function Point:update(dt) end

function Point:get()
  if type(self.x) == 'function' then
    return v()
  else
    return v
  end
end

function Point:mouse_move(x, y)
  self.selected = self:inside(x, y)
end

function Point:inside(x, y)
  local dx, dy = self.get(self.x)-x, self.get(self.y)-y

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
    }
  })

  local points = envelope.state.points

  push(points, Point:new(0, 0, true))

  return envelope
end

function Envelope:render(state)
  return {
    x = state.x, y = state.y,
    w = state.w, h = state.h,

    background = 8,

    draw = function(w)
      Widget.draw(w)

      for _, point in ipairs(state.points) do
        point:draw()
      end
    end,

    move = function(w, event, a)
      Widget.move(w, event, a)

      for _, point in ipairs(state.points) do
        point:mouse_move(event.x, event.y)
      end
    end,

    update = function(w, dt)
      Widget.update(w, dt)

      for _, point in ipairs(state.points) do
        point:update(dt)
      end

      self:set_state(self.state)
    end
  }
end

return Envelope