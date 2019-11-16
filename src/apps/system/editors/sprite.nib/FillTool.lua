local FillTool = {}

function FillTool:new()
  return new(FillTool, {})
end

function FillTool:press(preview, sprite, x, y, color)
  sprite:fill(x, y, color)
end

function FillTool:release(sprite, x, y)
end

function FillTool:move(sprite, x, y, nx, ny, color)
end

return FillTool
