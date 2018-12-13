local conf = require 'conf';

function init()
    if conf.mode == 'setup' then
        kernel.exec('apps/system/core/setup.nib', {})
    elseif conf.mode == 'dev' then
        -- Inicializa o serviço de terminal
        local tty, err = kernel.exec("apps/system/core/terminal.nib", {})

        -- Roda o shell
        local sh, err = kernel.exec("apps/system/core/shell.nib", {
            tty=tostring(tty)
        })
    else
        -- Inicializa o launcher
        kernel.exec("apps/system/core/launcher.nib", {})
    end

    kernel.kill(0)
end
