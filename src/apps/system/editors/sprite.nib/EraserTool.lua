local EraserTool = {}

function EraserTool:new()
  return new(EraserTool, {})
end

function EraserTool:press(preview, sprite, x, y, color)
  sprite:put_pixel(x, y, 0)
end

function EraserTool:release(sprite, x, y)
end

function EraserTool:move(sprite, x, y, nx, ny, color)
  sprite:line(x, y, nx, ny, 0)
end

return EraserTool
