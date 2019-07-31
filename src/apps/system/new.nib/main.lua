-- new.nib

function tty_print(str)
    send_message(env.tty, { print = str })
end

function enable_tty()
    send_message(env.shell, { tty = true })
end

function make_directory(directory)
    tty_print("[DIR] ")
    tty_print(directory)
    tty_print("\n")

    create_directory(directory)
end

function make_file(file)
    tty_print("[FILE] ")
    tty_print(file)
    tty_print("\n")

    create_file(file)
end

function init()
    enable_tty()

    local app_name = env.params[2]

    local dir = "apps/"..app_name..".nib"
    local main = dir.."/".."main.lua"

    make_directory(dir)
    make_file(main)

    stop_app(0)
end
