-- help.nib

function init()
    -- Enable tty
    send_message(env.shell, { tty = true })

    send_message(env.tty, { print = "Type the name of the app you want to\nstart after the \"~\" prompt\n\n" })
    send_message(env.tty, { print = "For extra help, check out https://github.com/pongboy/nibble/\n\n" })

    stop_app(0)
end
