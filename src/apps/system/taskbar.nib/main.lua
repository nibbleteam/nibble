local NOM = require "nibui.NOM"

--Constants
local taskbarHeight = 25

--Get all editors
local editorPaths = list_directory("apps/system/editors")
local editorButtons = {}
    --Prepare buttons for editors
for k=1,#editorPaths do
    if type(k) == "number" then
        if not (k < 3) then -- Skip . and ..
            editorButtons[#editorButtons+1] = {
                x = NOM.left+(23*(k-3))+(2*(k-2)), y = NOM.top+2,
                w = 23, h = 23,
                background = 4,
                id = editorPaths[k],
                onclick = function(self)
                    self.parent:select(self.id)
                end
            }
        end
    end
end

--ui
local ui = NOM:new({
    x = NOM.left,  y = NOM.top,
    w = NOM.width, h = NOM.height,
    background = 1,
    running = nil,
    {
      x = NOM.left,  y = NOM.top,
      w = NOM.width, h = NOM.height-taskbarHeight,
      id = "editor"
    },
    {
        x = NOM.left,  y = NOM.bottom-taskbarHeight,
        w = NOM.width, h = taskbarHeight,
        background = 3,

        selected = nil,
        running = nil,
        
        select = function(self,id)
            if self.selected ~= id then
                self:find(id).y -= 1
                if self.select ~= nil then
                    self:find(self.selected).y += 1
                    stop_app(self.running)
                end
                self.running = start_app(id,{
                    x=0,y=0,
                    width=400,height=240-25
                })
                self.selected = id
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
