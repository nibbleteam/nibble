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
        if not file:match 'frameworks/kernel' and
           not file:match '[C]' then
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
end
