local NOM = require 'nibui.NOM'

local nom = NOM:new(require 'nom'):use('cursor')

local reboot_msg = 'Please reboot the console (Ctrl-R)'

reboot = false

function init()
    cppal(0, 1)
    mask(16)
end

function draw()
    if reboot then
        clr(0)
        print(reboot_msg, 160-#reboot_msg*4, 116)
    else
        nom:draw()
    end
end

function update(dt)
    if reboot then
    else
        nom:update(dt)
    end
end
