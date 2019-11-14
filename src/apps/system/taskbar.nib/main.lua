local NOM = require "nibui.NOM"
local Widget = require "nibui.Widget"

-- Constants
local taskbarHeight = 18

local iconWidth = 16
local iconHeight = 16
local iconGap = 0
local iconJump = 1

-- Get all editors
local editorPaths = list_directory("apps/system/editors")
local editorButtons = {}

-- Prepare buttons for editors
for k=1,#editorPaths do
    if type(k) == "number" then
        if not (k < 3) then -- Skip . and ..
            editorButtons[#editorButtons+1] = {
                x = NOM.left+(iconWidth*(k-3))+(iconGap*(k-2)), y = NOM.top+iconJump,
                w = iconWidth, h = iconHeight,
                background = { 2, 3+k },
                id = editorPaths[k],

                pid = nil,

                onclick = function(self)
                    self.parent:select(self.id, self)
                end
            }
        end
    end
end

-- UI
local ui = NOM:new({
    x = NOM.left,  y = NOM.top,
    w = NOM.width, h = NOM.height,

    -- Background when no apps are running
    {
        x = NOM.left,  y = NOM.top,
        w = NOM.width, h = NOM.height-taskbarHeight,
        id = "editor",

        draw = function(self)
            if self.dirty and not self.parent:find("taskbar").selected then
                Widget.draw(self)

                local side = 16

                -- Draw a checkers pattern
                for y=self.y,self.h,side do
                    for x=self.x,self.w,side do
                        fill_rect(x, y, side, side, (x/side+y/side) % 2 + 1)
                    end
                end
            end
        end
    },

    -- The taskbar itself
    {
        id = "taskbar",

        x = NOM.left,  y = NOM.bottom-taskbarHeight,
        w = NOM.width, h = taskbarHeight,
        background = 3,

        selected = nil,
        running = nil,
        
        select = function(self, id, widget)
            if self.selected ~= id then
                -- Move the icon up
                widget.y -= iconJump
                -- and select the bright background
                widget.background[1] -= 2

                -- If there was an app running, pause it
                if self.selected ~= nil then
                    local prevWidget = self:find(self.selected)
                    -- and also move its icon down
                    prevWidget.y += iconJump
                    -- and select the dark background
                    prevWidget.background[1] += 2

                    pause_app(self.running)
                end

                -- If this app has a running process
                if widget.pid then
                    -- just resume it
                    resume_app(widget.pid)

                    self.running = widget.pid
                else
                    -- otherwise start it from the ground up
                    widget.pid = start_app(id,{
                        x=0,y=0,
                        width=env.width,
                        height=env.height-taskbarHeight
                    })

                    self.running = widget.pid
                end

                -- Mark as selected
                self.selected = id

                -- Redraw
                widget:set_dirty()
            end
        end,

        unwrap(editorButtons)
    }

}):use('cursor')

function draw()
    ui:draw()
end

function update(dt)
    ui:update(dt)
end
