local Editor = {}

local Line = require 'Line'
local Cursor = require 'Cursor'

local EDITOR_BACKGROUND = 16

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
                 height = 24,
                 start_x = 0,
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
  fill_rect(x, y, w, h, EDITOR_BACKGROUND)

  local line = self.view.start

  for i=1,self.view.height do
    if not line then
      break
    end

    line:draw(x+self.view.start_x, y)

    if self.cursor:is_in_line(line) then
      self.cursor:draw(x+self.view.start_x, y)
    end

    y = y + line:height()

    line = line.next
  end

  if self.cursor:to_left(-self.view.start_x) then
    self.view.start_x = -self.cursor:screen_position()+8
  end

  if self.cursor:to_right(w - self.view.start_x) then
    self.view.start_x = -self.cursor:screen_position()+w
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
    if line.next then 
      text = text .. line.content .. "\n"
    else
      text = text .. line.content
    end
  
    line = line.next
  end

  return text
end

return Editor
