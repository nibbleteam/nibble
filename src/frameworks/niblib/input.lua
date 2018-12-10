local input = {}

CONTROLLER = 81604

input.STUP = 0
input.STPRESSED = 1
input.STDOWN = 2
input.STRELEASED = 3

input.UP = 0
input.RIGHT = 1
input.DOWN = 2
input.LEFT = 3

input.RED = 4
input.BLUE = 5

input.BLACK = 6
input.WHITE = 7

function input.bt(b)
  assert(b, "bt() needs a button")

  b = math.floor(b)%8

  local value;

  if b < 4 then
    value = kernel.read(CONTROLLER+1, 1):byte()
  else
    value = kernel.read(CONTROLLER+2, 1):byte()
  end

  if b%4 == input.UP then
    return math.floor(value/64)
  elseif b%4 == input.RIGHT then
    return math.floor((value-math.floor(value/64)*64)/16)
  elseif b%4 == input.DOWN then
    return math.floor((value-math.floor(value/16)*16)/4)
  elseif b%4 == input.LEFT then
    return value-math.floor(value/4)*4
  end
end

return input
