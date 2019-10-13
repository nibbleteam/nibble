-- help.nib

function init()
    local dirnames = { 'apps/', 'apps/system/' };

    -- Enable tty
    send_message(env.shell, { tty = true })

    send_message(env.tty, { print = "Type the name of the app you want to\nstart after the \"~\" prompt\n\n" })
    send_message(env.tty, { print = "For extra help, check out https://github.com/pongboy/nibble/\n\n" })

    send_message(env.tty, { print = "AVAILABLE APPS\n\n" })

    for _, dirname in ipairs(dirnames) do
        local dirs = list_directory(dirname)

        local chars_in_line = 0

        for _, dir in ipairs(dirs) do
            local app = dir:match("(%w*)%.nib")

            if app then
                send_message(env.tty, { print = app, background = 2 })
                send_message(env.tty, { print = " " })

                chars_in_line += #app

                if chars_in_line >= 30 then
                    chars_in_line = 0
                    send_message(env.tty, { print = "\n" })
                end
            end
        end
    end

    send_message(env.tty, { print = "\n" })

    stop_app(0)
end
