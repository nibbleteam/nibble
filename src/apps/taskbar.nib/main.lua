local NOM = require 'nibui.NOM'
local taskbar = NOM:new(require 'taskbar')

pids = {
    music = 0,
    code = 0,
    sprite = 0,
}

running = {}

function init_colors()
    copy_palette(0, 1)
    mask_color(0)
end

function init()
    init_colors()

    for editor, _ in pairs(pids) do 
        pids[editor], _ = start_app('apps/'..editor..'.nib', {})
    end

    run('music')
end

function update(dt)
    taskbar:update(dt)
end

function draw()
    taskbar:draw()
end

function run(target)
    for editor, _ in pairs(pids) do 
        if editor == target then
            send_system_message(pids[editor], 'play')

            running[editor] = true
            taskbar:find('#'..editor):onenter()
        else
            send_system_message(pids[editor], 'pause')

            running[editor] = nil
            taskbar:find('#'..editor):onleave()
        end
    end
end
