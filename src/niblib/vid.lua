local vid = {}

function vid.putp(x, y, color)
  assert(x, "putp() needs a x value")
  assert(y, "putp() needs a y value")
  assert(color, "putp() needs a color value")

  x = math.abs(math.floor(x))%320
  y = math.abs(math.floor(y))%240

  color = math.abs(math.floor(color))%256

  kernel.write(y*320+x+0x220, string.char(color))
end

function vid.getp(x, y)
  assert(x, "getp() needs a x value")
  assert(y, "getp() needs a y value")

  x = math.abs(math.floor(x))%320
  y = math.abs(math.floor(y))%240

  return kernel.read(y*320+x+0x220, 1):byte()
end

return vid
