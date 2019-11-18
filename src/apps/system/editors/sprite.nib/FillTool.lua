local FillTool = {}

function FillTool:new(history)
  return new(FillTool, {
               name = "Fill Tool",
               history = history
  })
end

function FillTool:press(preview, sprite, x, y, color)
  self.history:snapshot(sprite, sprite:fill(x, y, color))
end

function FillTool:release(sprite, x, y)
end

function FillTool:move(sprite, x, y, nx, ny, color)
end

return FillTool
