local NOM = require 'nibui.NOM'
local Widget = require 'nibui.Widget'

local Editor = require 'Editor'

local editor_margin = 1

local AUTOPRESS_TIME = 0.01
local AUTOPRESS_WAIT = 0.25

local function write_file(file, text)
    local f = io.open(file, "w")

    if f then
        f:write(text)
        f:close()

        return true
    end

    return nil
end

local function autopress(button, action)
    if button_press(button) then
        local function move()
            if button_down(button) then
                action()

                set_timeout(AUTOPRESS_TIME, move)
            end
        end

        local function move_wait_and_move()
            action()

            set_timeout(AUTOPRESS_WAIT, function()
                            if button_down(button) then
                                move()
                            end
            end)
        end

        move_wait_and_move();
    end
end

return {
    w = NOM.width-2*editor_margin,
    h = NOM.height-2*editor_margin,
    x = NOM.left+editor_margin,
    y = NOM.top+editor_margin,

    background = 16,

    draw = function (self)
        local text_breathing = 0

        if not self.editor then
            self.editor = Editor:new(self.code, math.ceil((self.h)/10))
        end

        Widget.draw(self)

        clip(self.x, self.y, self.w, self.h)

        self.editor:draw(self.x, self.y, self.w, self.h)
    end,

    onclick = function(self, event)
        if self.editor then
            self.editor:move_to_mouse(event.x-self.x, event.y-self.y)
        end
    end,

    onmove = function(self, event)
        if event.drag and self.editor then
            self.editor:move_to_mouse(event.x-self.x, event.y-self.y)
        end
    end,

    onenter = function(self)
        self.document:set_cursor("cursor")
    end,

    onleave = function(self)
        self.document:set_cursor("default")
    end,

    update = function(self)
        if not self.editor then
            return
        end

        -- TODO: use NOM's event system
        local input = read_keys()

        for i=1,#input do
            local char = input:sub(i, i)

            if char == "\08" then
                if self.editor:look_at(-2) == "  " then
                    self.editor:remove_chars(-2)
                else
                    self.editor:remove_chars(-1)
                end
            elseif char == "\127" then
                self.editor:remove_chars(1)
            elseif char == "\09" then
                self.editor:insert_chars("  ")
            elseif char == "\13" then
                self.editor:insert_line()
            else
                self.editor:insert_chars(char)
            end

            -- TODO: use save signal
            write_file(self.filename, self.editor:text())
        end

        autopress(RIGHT, function()
                      self.editor:move_by_chars(1)
        end)


        autopress(LEFT, function()
            self.editor:move_by_chars(-1)
        end)

        autopress(DOWN, function()
            self.editor:move_by_lines(1)
        end)

        autopress(UP, function()
            self.editor:move_by_lines(-1)
        end)

        if #input > 0 then
            self:set_dirty()
        end

        local sx, sy = mouse_scroll()

        if sy ~= 0 then
            self.editor:move_by_lines(sy*4)
        end
    end
}
