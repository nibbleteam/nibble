local PencilTool = {}

function PencilTool:new(history)
  return new(PencilTool, {
               name = "pencil tool",

               history = history,
               bounding_box = { 0, 0, 0, 0 }
  })
end

function PencilTool:press(preview, sprite, x, y, color)
  sprite:put_pixel(x, y, color)

  self.bounding_box = {
    x, y,
    x, y,
  }
end

function PencilTool:release(sprite, x, y)
  self.history:snapshot(sprite, unwrap(self.bounding_box))
end

function PencilTool:move(sprite, x, y, nx, ny, color)
  sprite:line(x, y, nx, ny, color)

  self.bounding_box = {
    math.min(self.bounding_box[1], nx), math.min(self.bounding_box[2], ny),
    math.max(self.bounding_box[3], nx), math.max(self.bounding_box[4], ny)
  }
end

return PencilTool
