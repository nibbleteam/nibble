function init()
    -- Inicializa o serviço de terminal
    --local tty, err = kernel.exec("apps/system/core/terminal.nib", {})

    -- Roda o shell
    --local sh, err = kernel.exec("apps/system/core/shell.nib", {
    --    tty=tostring(tty)
    --})

    --start_app("apps/taskbar.nib", {})
    start_app("apps/synth.nib", {})
    stop_app(0)
end
