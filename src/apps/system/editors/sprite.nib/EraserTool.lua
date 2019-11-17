local EraserTool = {}

function EraserTool:new(history)
  return new(EraserTool, {
               history = history,
               bounding_box = { 0, 0, 0, 0 }
  })
end

function EraserTool:press(preview, sprite, x, y, color)
  sprite:put_pixel(x, y, 0)
end

function EraserTool:release(sprite, x, y)
  self.history:snapshot(sprite, unwrap(self.bounding_box))
end

function EraserTool:move(sprite, x, y, nx, ny, color)
  sprite:line(x, y, nx, ny, 0)

  self.bounding_box = {
    math.min(x, nx), math.min(y, ny),
    math.max(x, nx), math.max(y, ny)
  }
end

return EraserTool
