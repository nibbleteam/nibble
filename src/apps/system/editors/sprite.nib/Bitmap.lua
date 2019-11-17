local Bitmap = {}

-- In filled pixels
local FILL_LIMIT = 1024*128

function Bitmap:new(width, height, data, solid)
  return new(Bitmap, {
               width = width or 0,
               height = height or 0,

               data = data or {},

               solid = (solid and from_ascii(solid)) or nil,
  })
end

function Bitmap:clear()
  self.data = {}
end

function Bitmap:check_bounds(x, y)
  return
    x >= 0 and x < self.width and
    y >= 0 and y < self.height
end

function Bitmap:put_pixel(x, y, color)
  if self:check_bounds(x, y) then
    local p = y*self.width+x;

    self.data[p] = from_ascii(color%16)
  end
end

function Bitmap:get_pixel(x, y)
  if self:check_bounds(x, y) then
    local p = y*self.width+x;

    return self.data[p]:byte()
  end
end

function Bitmap:line(x1, y1, x2, y2, color)
  if x1 == x2 and y1 == y2 then
    self:put_pixel(x1, y1, color)

    return
  end

  x1 += 0.5
  y1 += 0.5
  x2 += 0.5
  y2 += 0.5

  local dx, dy = x2-x1, y2-y1
  local l = math.max(math.abs(dx), math.abs(dy))

  dx, dy = dx/l, dy/l

  for i=1,l+1 do
    self:put_pixel(math.floor(x1), math.floor(y1), color)

    x1 += dx
    y1 += dy
  end
end

function Bitmap:fill(x, y, color)
  local frontier = { { x, y } }
  local box = {
    x, y,
    x, y,
  }

  local original = self:get_pixel(x, y)

  local i = 0

  while #frontier > 0 do
    i += 1

    if i > FILL_LIMIT then
      break
    end

    local x, y = unwrap(shift(frontier))

    self:put_pixel(x, y, color)

    -- Conditionally add neighbors
    for dx=-1,1 do
      for dy=-1,1 do
        if dx == 0 or dy == 0 then
          if self:get_pixel(x+dx, y+dy) == original then
            self:put_pixel(x+dx, y+dy, color)

            push(frontier, { x+dx, y+dy })

            box = {
              math.min(box[1], x+dx), math.min(box[2], y+dy),
              math.max(box[3], x+dx), math.max(box[4], y+dy)
            }
          end
        end
      end
    end
  end

  return unwrap(box)
end

return Bitmap
