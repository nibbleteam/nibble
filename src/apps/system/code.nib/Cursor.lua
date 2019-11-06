local Cursor = {}

local Line = require 'Line'

function Cursor:new(line, position)
  return new(Cursor, {
               line = line,
               position = position,
               user_position = position,
  })
end

function Cursor:move_by_chars(char_count)
  local position = self.user_position

  self.position = math.min(math.max(position+char_count, 1), self.line:length()+1)

  if char_count ~= 0 and position ~= self.position then
    self.user_position = self.position
  end
end

function Cursor:move_by_lines(line_count)
  if line_count > 0 then
    for i=1,line_count do
      if self.line.next then
        self.line = self.line.next
      else
        break
      end
    end
  elseif line_count < 0 then
    for i=1,-line_count do
      if self.line.prev then
        self.line = self.line.prev
      else
        break
      end
    end
  end

  self:move_by_chars(0)
end

function Cursor:insert_chars(str)
  local content = self.line.content

  self.line.content = content:sub(1, self.position-1)..str..content:sub(self.position, -1)
  self.line:highlight()

  self:move_by_chars(#str)
end

function Cursor:remove_chars(char_count)
  local content = self.line.content

  if char_count < 0 then
    if self.position > 1  then
      self.line.content = content:sub(1, self.position+char_count-1)..content:sub(self.position, -1)
      self:move_by_chars(char_count)
    else
      self:merge_lines(-1)
    end
  end

  if char_count > 0 then
    if self.position > 0 then
      self.line.content = content:sub(1, self.position-1)..content:sub(self.position+char_count, -1)
    else
      self.merge_lines(1)
    end
  end

  self.line:highlight()
end

function Cursor:merge_lines(line_count)
  if line_count < 0 and self.line.prev then
    self.position = self.line.prev:length()+1
    self.user_position = self.position

    if self.line.next then
        self.line.next.prev = self.line.prev
    end

    self.line.prev.next = self.line.next
    self.line.prev.content = self.line.prev.content..self.line.content

    self.line = self.line.prev
  else
    if self.line.next then
      self.line.content = self.line.content .. self.line.next.content
      self.line.next = self.line.next.next
    end
  end

  self.line:highlight()
end

function Cursor:insert_line()
  local weight =
    self.line.next and (self.line.weight+self.line.next.weight)/2 or self.line.weight+1

  local new_line = Line:new(self.line.content:sub(self.position, -1), self.line, weight)
  self.line.content = self.line.content:sub(1, self.position-1)

  if self.line.next then
    self.line.next.prev = new_line
  end

  new_line.next = self.line.next
  self.line.next = new_line

  self.line = new_line

  -- Move para o inicio da linha
  self.user_position = 1

  self:move_by_chars(0)
end

function Cursor:is_in_line(line)
  return line == self.line
end

function Cursor:to_right(x)
  return self:screen_position() > x
end

function Cursor:to_left(x)
  return self:screen_position() < x
end

function Cursor:screen_position()
  return self.line.offset_x + self.position * 8
end

function Cursor:draw(x, y)
  fill_rect(self.line.offset_x+x+(self.position-1)*8, self.line.offset_y+y, 1, 8, 15)
end

return Cursor








