local NOM = require 'nibui.NOM'
local nom = nil

function read_file(file)
    local f = assert(io.open(file))
    local content = f:read("*all")
    f:close()

    return content
end

function print_available_apps_and_exit()
    local dirname = 'apps/';

    -- Enable tty
    send_message(env.shell, { tty = true })

    send_message(env.tty, { print = "Use: code <app>\n" })

    send_message(env.tty, { print = "listing "})
    send_message(env.tty, { print = "apps/\n", background = 3 })

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

    send_message(env.tty, { print = "\n" })

    stop_app(0)
end

function init()
    if env.params[2] then
        local code = read_file('apps/'..env.params[2]..'.nib/main.lua')

        nom = NOM:new({
            w = 320,
            h = 240,
            x = 0, y = 0,
            background = 11,
            NOM.require("editor", { code = code })
        }):use('cursor')
    else
        print_available_apps_and_exit()
    end
end

function draw()
    nom:draw()
end

function update(dt)
    local msg = receive_message()

    if msg then
        if msg.resume then
            nom.root:set_dirty()
        end
    end

    nom:update(dt)
end
