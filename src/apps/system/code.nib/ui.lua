local NOM = require 'nibui.NOM'

local Editor = require 'Editor'

local editor_margin = 0

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

    background = 1,

    draw = function (self)
        if not self.editor then
            self.editor = Editor:new(self.code)
        end

        clip(self.x, self.y, self.w, self.h)

        self.editor:draw(self.x, self.y, self.w, self.h)
    end,

    update = function(self)
        local input = read_keys()

        for i=1,#input do
            local char = input:sub(i, i)

            if char == "\08" then
                self.editor:remove_chars(-1)
            elseif char == "\127" then
                self.editor:remove_chars(1)
            elseif char == "\09" then
                self.editor:insert_chars("  ")
            elseif char == "\13" then
                self.editor:insert_line()
            else
                self.editor:insert_chars(char)
            end

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
    end
}
