-- :?))))
-- By Felipe Tavares
-- Complex number operations
function cmul(a, b)
  return {
    a[1]*b[1] - a[2]*b[2],
    a[1]*b[2] + a[2]*b[1]
  }
end

function cadd(a, b)
  return {
    a[1] + b[1], a[2] + b[2]
  }
end

function cmag(c)
  return c[1]*c[1] + c[2]*c[2]
end

local t0 = clock()

-- Scaling the fractal
function camera(x, y)
  local t = clock() - t0

  --local scale = (math.sin(clock())+1.5)/100
  local scale = 1/(t*t)
  local off_x = math.sin(clock()/2)*env.width/4
  local off_y = math.cos(clock()/2)*env.height/4
  
  return {
    (x-env.width/2)*scale+off_x/100,
    (y-env.height/2)*scale+off_y/100
  }
end

-- Fractal
function mandelbrot(c)
  local z = { 0, 0 }
  local max = 1000000000
  local max_it = 128
  local i = 1
  
  while cmag(z) < max and i < max_it do
    z = cadd(cmul(z, z), c)
    
    i += 1
  end
  
  return i
end

-- Drawing
function draw()
  for x=0, env.width do
    for y=0, env.height do
      -- Translates and scales x, y as needed
      local c = camera(x, y)
      
      local color = mandelbrot(c)
      
      rect(x, y, 1, 1, color)
    end
  end
end