local Textarea = require 'nibui.Textarea'
local Text = require 'nibui.Text'

local area = Textarea:new(8, 8, 320-16, 240-16)

function print_file(file)
  for path, file in file:gmatch '(.*).nib/(.*)' do
    area:add(Text:new('in '))
    area:add(Text:new(file):set('background_color', 3):set('color', 14))
    area:add(Text:new(' @ line '))
  end
end

function init()
   write(0, '\x14\x0c\x1c\xff\x44\x24\x34\xff\x30\x34\x6d\xff\x4e\x4a\x4e\xff\x85\x4c\x30\xff\x34\x65\x24\xff\xd0\x46\x48\xff\x75\x71\x61\xff\x59\x7d\xce\xff\xd2\x7d\x2c\xff\x85\x95\xa1\xff\x6d\xaa\x2c\xff\xd2\xaa\x99\xff\x6d\xc2\xca\xff\xda\xd4\x5e\xff\xde\xee\xd6\xff')
   mask_color(0)

  for file, line, error in env.error:gmatch '(.*):(.*): (.*)' do
    print_file(file)

    area:add(Text:new(line):set('background_color', 6))
    area:newline()
    area:newline()
    area:add(Text:new(error):set('color', 6))
    area:newline()
    area:newline()
  end

  for file, line, fn in env.traceback:gmatch '\t([^\n]+):(%d+): in function ([^\n]+)' do
    if not file:match 'frameworks/kernel' and not file:match '[C]' then
      print_file(file)
      area:add(Text:new(line):set('background_color', 8))
      area:newline()
      area:add(Text:new(fn):set('color', 11))
      area:newline()
    end
  end
end

function draw()
  clear(1)
  area:draw()
end

function update(dt)
  if button_press(UP) then
    area:scroll(8)
  end

  if button_press(DOWN) then
    area:scroll(-8)
  end

  if button_press(RED) then
    stop_app(0)
  end
end
