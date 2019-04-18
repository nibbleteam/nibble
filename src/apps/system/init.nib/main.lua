local conf = require 'conf';

function init()
    if conf.mode == 'setup' then
        kernel.exec('apps/system/setup.nib', {})
    elseif conf.mode == 'dev' then
        -- Inicializa o serviço de terminal
        --local tty, err = kernel.exec("apps/system/core/terminal.nib", {})

        -- Roda o shell
        --local sh, err = kernel.exec("apps/system/core/shell.nib", {
        --    tty=tostring(tty)
        --})

        -- Roda a taskbar
        kernel.exec("apps/taskbar.nib", {})
        --kernel.exec("apps/test.nib", {})
    else
        -- Inicializa o launcher
        kernel.exec("apps/system/launcher.nib", {})
    end

    kernel.kill(0)
end
