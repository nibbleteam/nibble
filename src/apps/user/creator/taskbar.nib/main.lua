local NOM = require 'nibui.NOM'

local taskbar = NOM:new(require 'taskbar')

local music_pid = 0

function init()
    cppal(0, 1)
    mask(0)

    -- Roda os editores
    music_pid, _ = kernel.exec('apps/user/creator/music.nib', {})
end

function update(dt)
    taskbar:update(dt)
end

function draw()
    taskbar:draw()
end
