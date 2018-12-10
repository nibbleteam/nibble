function init()
    -- Inicializa o serviço de terminal
    local tty, err = kernel.exec("apps/system/core/terminal.nib", {})

    -- Roda o shell
    local sh, err = kernel.exec("apps/system/core/shell.nib", {
        tty=tostring(tty)
    })
    
    --kernel.exec('apps/user/creator/music.nib', {})

    kernel.kill(0)
end
