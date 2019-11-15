local NOM = require "nibui.NOM"
local Widget = require "nibui.Widget"

-- Constants
local taskbarHeight = 17
local taskbarBackgroundColor = 3
local taskbarHighlightColor = 7
local taskbarSilhouetteColor = 1

local iconWidth = 16
local iconHeight = 16
local iconGap = 0
local iconJump = 2

local iconMap = {
    8,
    9,
    6,
    7,
}

-- Get all editors
local editorPaths = list_directory("apps/system/editors")
local editorButtons = {}

-- Prepare buttons for editors
for k=1,#editorPaths do
    if type(k) == "number" then
        if not (k < 3) then -- Skip . and ..
            editorButtons[#editorButtons+1] = {
                x = NOM.left+(iconWidth*(k-3))+(iconGap*(k-2)), y = NOM.top+iconJump-1,
                w = iconWidth, h = iconHeight,
                background = { 2, iconMap[k-2] },
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
                local colors = { 16, 1 }

                -- Draw a checkers pattern
                for y=self.y,self.h,side do
                    for x=self.x,self.w,side do
                        fill_rect(x, y, side, side, colors[(x/side+y/side) % 2 + 1])
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
        background = taskbarBackgroundColor,

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
                        height=env.height-taskbarHeight,

                        params = {}
                    }, true)

                    self.running = widget.pid
                end

                -- Mark as selected
                self.selected = id
            end
        end,

        -- A little highlight line
        {
            x = NOM.left, y = NOM.top,
            w = NOM.width, h = 1,

            background = taskbarHighlightColor
        },
        -- A little silhouette line
        {
            x = NOM.left, y = NOM.top+1,
            w = NOM.width, h = 1,

            background = taskbarSilhouetteColor
        },

        -- A "reload" button
        {
            x = NOM.right-16, y = NOM.bottom-taskbarHeight,
            w = 16, h = 16,

            background = 9,

            content = "R",

            onclick = function(self)
                local taskbar = self.parent:find("taskbar")

                if taskbar.selected then
                    local widget = self.parent:find(taskbar.selected)

                    -- Disable grouping so we don't kill ourselves too
                    stop_app(widget.pid, true)

                    widget.pid = start_app(taskbar.selected, {
                        x=0,y=0,
                        width=env.width,
                        height=env.height-taskbarHeight,

                        params = {}
                    }, true)

                    taskbar.running = widget.pid
                end
            end
        },

        unwrap(editorButtons)
    }

}):use('cursor')

function draw()
    ui:draw()
end

function update(dt)
    ui:update(dt)
end
