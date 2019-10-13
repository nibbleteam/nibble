local Line = {}

function Line:new(content, prev, weight)
  return new(Line, {
               content = content or "",
               prev = prev,
               next = nil,
               weight = weight,
  })
end

function Line:length()
  return #self.content
end

function Line:height()
  return 10
end

function Line:draw(x, y)
  print(self.content, x, y)
end

return Line
