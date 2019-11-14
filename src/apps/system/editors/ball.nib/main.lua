-- Ball info

-- Position
local x, y = 0, 0
-- Velocity
local vx, vy = 300, 150
-- Size
local radius = 8
-- Color
local color = 6

-- Draw the ball on the screen
function draw()
  clear(1)

  fill_circ(x, y, radius, color)
end

function update(dt)
  x += vx*dt
  y += vy*dt

  local max_x = env.width-radius
  local min_x = radius
  local max_y = env.height-radius
  local min_y = radius

  if x >= max_x then
    x = max_x
    vx *= -1
  end

  if x < min_x then
    x = min_x
    vx *= -1
  end

  if y >= max_y then
    y = max_y
    vy *= -1
  end

  if y < min_y then
    y = min_y
    vy *= -1
  end
end
