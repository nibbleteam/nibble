local PencilTool = {}

function PencilTool:new()
  return new(PencilTool, {

  })
end

function PencilTool:press(preview, sprite, x, y, color)
  sprite:put_pixel(x, y, color)
end

function PencilTool:release(sprite, x, y)
end

function PencilTool:move(sprite, x, y, nx, ny, color)
  sprite:line(x, y, nx, ny, color)
end

return PencilTool
