local FillTool = {}

function FillTool:new(history)
  return new(FillTool, {
               name = "Fill Tool",
               history = history
  })
end

function FillTool:press(preview, sprite, x, y, color)
  -- b for bouding
  local bx, by, bw, bh = sprite:fill(x, y, color)

  if bx and by and bw and bh then
    self.history:snapshot(sprite, bx, by, bw, bh)
  end
end

function FillTool:release(sprite, x, y)
end

function FillTool:move(sprite, x, y, nx, ny, color)
end

return FillTool
