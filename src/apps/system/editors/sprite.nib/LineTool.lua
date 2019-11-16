local LineTool = {}

function LineTool:new()
  return new(LineTool, {
               preview = nil,
               color = 0,
               start_x = 0,
               start_y = 0,
               end_x = 0,
               end_y = 0,
  })
end

function LineTool:press(preview, sprite, x, y, color)
  self.start_x = x
  self.start_y = y
  self.color = color

  self.preview = preview
end

function LineTool:release(sprite, x, y)
  if self.preview then
    self.preview:clear()
    sprite:line(self.start_x, self.start_y, x, y, self.color)
  end
end

function LineTool:move(sprite, x, y, nx, ny, color)
  if self.preview then
    self.preview:clear()
    self.preview:line(self.start_x, self.start_y, nx, ny, self.color)
  end
end

return LineTool
