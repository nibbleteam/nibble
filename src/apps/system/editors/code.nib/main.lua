env.menu = {
    'Code Editor',
    'v0.2.0',
    '',
    'by Felipe Tavares'
}

require 'lang.timeout'

local NOM = require 'nibui.NOM'
local nom = nil

function read_file(file)
    local f = io.open(file)

    if f then
        local content = f:read("*all")
        f:close()

        return content:gsub("\r", "")
    end
end

function print_available_apps_and_exit(not_found)
    local dirname = 'apps/';

      -- Enable tty
    send_message(env.shell, { tty = true })

    if not_found then
        send_message(env.tty, { print = "app entrypoint not found\n" })
    end

    send_message(env.tty, { print = "Use: code <app>\n" })

    send_message(env.tty, { print = "listing "})
    send_message(env.tty, { print = "apps/\n", background = 3 })

    local dirs = list_directory(dirname)

    local chars_in_line = 0
  
    for _, dir in ipairs(dirs) do
          local app = dir:match("/(.*).nib")

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

function create_ui(code, opened_file)
    nom = NOM:new({
            w = env.width,
            h = env.height,
            x = env.x, y = env.y,
            background = 11,

            NOM.require("ui", { code = code, filename = opened_file }),
    }):use("cursor")
end
    
function init()
    if env.params[2] then
        local filenames = {
            'apps/'..env.params[2]..'.nib/main.lua',
            'apps/system/'..env.params[2]..'.nib/main.lua',
            'apps/'..env.params[2]..'/main.lua',
            'apps/system/'..env.params[2]..'/main.lua',
            'frameworks/'..env.params[2]..'/main.lua',
            'apps/'..env.params[2]..'.lua',
            'apps/system/'..env.params[2]..'.lua',
            'frameworks/'..env.params[2]..'.lua',
            env.params[2]
        }

        local code, opened_file

          for _, filename in ipairs(filenames) do
            code = read_file(filename)

            if code then
                opened_file = filename
                break
            end
        end

        if code then
            create_ui(code, opened_file)
        else
            return print_available_apps_and_exit(true)
        end
    else
        -- print_available_apps_and_exit()
        create_ui("", "unamed.lua")
    end

    send_message(env.taskbar, {
        kind = "notification",
        content = "Lets hack!",
    })

    send_message(env.taskbar, {
        kind = "set_menu",
        menu = {
            color = 11,
            secondary_color = 5,
            items = {
                -- {
                --     name = "File", icon = nil,
                --     items = {
                --         { name = "Save", icon = nil },
                --         { name = "Open", icon = nil },
                --     },
                -- },
            }
        }
    })
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

    run_timeouts(dt)
end
