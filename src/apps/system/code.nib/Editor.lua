local Editor = {}

local Line = require 'Line'
local Cursor = require 'Cursor'

function Editor.build_lines(text)
  if text == "" then
    text = "\n"
  end

  local first_line = nil
  local prev_line = nil
  local raw_prev_line = nil

  local number = 1

  for line, _ in text:gmatch("[^\n]*") do
    if not (raw_prev_line ~= "" and line == "") then
      local new_line = Line:new(line, prev_line, number)

      if prev_line then
        prev_line.next = new_line
      end

      if not first_line then
        first_line = new_line
      end

      prev_line = new_line

      number = number+1
    end

    raw_prev_line = line
  end

  return first_line
end

function Editor:new(text)
  local first_line = Editor.build_lines(text)

  return new(Editor, {
               cursor = Cursor:new(first_line, 1),
               view = {
                 start = first_line,
                 height = 24
               },
               first = first_line,
  })
end

function Editor:move_by_chars(char_count)
  self.cursor:move_by_chars(char_count)
end

function Editor:move_by_lines(line_count)
  self.cursor:move_by_lines(line_count)
end

function Editor:insert_chars(chars)
  self.cursor:insert_chars(chars)
end

function Editor:remove_chars(char_count)
  self.cursor:remove_chars(char_count)
end

function Editor:insert_line()
  self.cursor:insert_line()
end

function Editor:draw(x, y, w, h)
  fill_rect(x, y, w, h, 1)

  local line = self.view.start

  for i=1,self.view.height do
    if not line then
      break
    end

    line:draw(x, y)

    if self.cursor:is_in_line(line) then
      self.cursor:draw(x, y)
    end

    y = y + line:height()

    line = line.next
  end

  if line and self.cursor.line.weight >= line.weight then
    if self.view.start.next then
        self.view.start = self.view.start.next
    end
  end

  if self.cursor.line.weight < self.view.start.weight then
    if self.view.start.prev then
        self.view.start = self.view.start.prev
    end
  end
end

function Editor:text()
  local line = self.first
  local text = ""

  while line do
    text = text .. line.content .. "\n"

    line = line.next
  end

  return text
end

return Editor
