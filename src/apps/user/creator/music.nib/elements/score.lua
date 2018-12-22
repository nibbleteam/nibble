local NOM = require 'nibui.NOM'
local Widget = require 'nibui.Widget'
local Easing = require 'nibui.Easing'
local d = NOM.dynamic

local line_height = 8
local cell_width = 24

local colors = {1, 3}
local highlight = 7
local note_colors = {10, 7}

local notes = {
    'A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#',
}

music = {}
music_period = 16

return {
    id = 'score',

    x = d'left', y = d'+'(d'top', 12),
    w = d'^' 'w', h = d'-'(d'^' 'h', 12),
    background = 1,

    press = { x = 0, y = 0 },
    offset = { x = 0, y = line_height*48 },
    ioffset = { x = 0, y = 0 },
    mouse = { x = 0, y = 0, drag = false},

    set_time = function(self, t)
        tick = math.floor(t*music_size)
        self.offset.x = -tick*cell_width
    end,

    note2screen = function(self, note, time)
        local x, y

        x = self.offset.x+self.x+(time)*cell_width+cell_width
        y = self.offset.y+self.y+self.h-(note+1)*line_height

        return x, y
    end,
    screen2note = function(self, x, y)
        local note, time

        time = math.floor((x-self.x-self.offset.x)/cell_width)-1
        note = math.floor((self.offset.y+self.y+self.h-y)/line_height)

        return note, time
    end,

    update_viewport = function (self)
        local current_time = -self.offset.x/cell_width
        local time_amount = self.w/cell_width-1

        self.document:find('#timeline'):update_view(current_time/music_size, time_amount/music_size)
    end,

    init = function (self)
        self:update_viewport()
    end,

    draw = function (self)
        if not (self.mouse.x or self.mouse.y) then
            self.mouse.x, self.mouse.y = 0, 0
        end

        local start_note, start_time = self:screen2note(self.x, self.y+self.h)
        local end_note, end_time = self:screen2note(self.x+self.w, self.y)
        local mnote, mtime = self:screen2note(self.mouse.x, self.mouse.y)

        local missing = self.h

        for n=start_note,end_note do
            local _, y = self:note2screen(n, 0)

            local coffset = 0
            
            if n == mnote then
                coffset = highlight
            end

            rectf(self.x+cell_width, math.max(y, self.y), self.w-cell_width, math.min(missing, line_height), colors[n%2+1]+coffset)

            for t=start_time+1,end_time do
                local x, _ = self:note2screen(n, t)
                local w, h = cell_width, math.min(missing, line_height)
                y = math.max(y, self.y)

                if music[t] and music[t][n] then
                    rectf(x, y, w, h, 11)
                    rect(x, y, w, h, 15)
                else
                    rect(x, y, w, h, colors[(n+1)%2+1])
                end
            end

            local timeline, _ = self:note2screen(0, tick)

            line(timeline, math.max(y, self.y), timeline, math.min(missing, line_height)+math.max(y, self.y)-1, 15)
            rectf(self.x, math.max(y, self.y), cell_width, math.min(missing, line_height), note_colors[n%2+1])
            if y > self.y then
                local octave = math.floor(n/12)

                print(tostring(octave)..notes[n%12+1], self.x, y+2)
            end

            missing -= math.min(line_height, self.y+self.h-y)
        end
    end,

    onpress = function (self, event)
        self.ioffset.x, self.ioffset.y = self.offset.x, self.offset.y
        self.press.x, self.press.y = event.x, event.y
    end,
    onclick = function (self, event)
        if not self.mouse.drag then
            local note, time = self:screen2note(event.x, event.y)

            if music[time] then
                music[time][note] = not music[time][note]
            else
                music[time] = { [note]=true }
            end
        end

        self.mouse.drag = false
    end,
    onmove = function (self, event)
        if event.drag then
            self.mouse.drag = true

            local off_x = self.ioffset.x+event.x-self.press.x
            local off_y = self.ioffset.y+event.y-self.press.y

            if off_y >= 0 then
                self.offset.y = off_y
            else
                self.offset.y = 0
            end

            if off_x <= 0 then
                if off_x < -music_size*cell_width+self.w-cell_width then
                    self.offset_x = -music_size*cell_width+self.w-cell_width
                else
                    self.offset.x = off_x
                end
            else
                self.offset.x = 0
            end

            self:update_viewport()
        end

        self.mouse.x, self.mouse.y = event.x, event.y
    end,
    onleave = function (self)
        self.mouse.x, self.mouse.y = 0, 0
    end,
}
