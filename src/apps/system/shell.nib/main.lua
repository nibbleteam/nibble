local tty

local name = 'shell.nib'
local prompt = "~"
local prompt_color = 9

sh = {
    path = {
        "apps/system/",
        "apps/demos/",
        "apps/",
    }
}

function shprint(str, bg)
    send_message(tty, { print = str, background = bg})
end

function print_prompt()
    shprint(prompt, prompt_color)
    shprint(' ')
end

function init()
    tty = env.tty

    -- Avisa que quer receber mensagens com entrada do usuário
    send_message(tty, { subscribe = env.pid, name = name })

    -- Desenha prompt
    print_prompt()
end

function update(dt)
    local input = receive_messages()

    if input then
        execute(input)
    end
end

function parse(line)
    local words = {}

    for word in line:gmatch('%w+') do
        insert(words, word)
    end

    return words
end

function execute(cmd)
    cmd = parse(cmd)

    if #cmd > 0 then
        local found = false

        for _, search_path in ipairs(sh.path) do
            local path = search_path..cmd[1]..".nib"

            local child, err = start_app(path, {
                                             tty = env.tty,
                                             shell = env.pid,
                                             params = cmd,
            })

            if child then
                send_message(tty, { unsubscribe=env.pid })
                send_message(tty, { disable = true })

                found = true

                break
            else
                if child == -4 then
                    shprint(err..'\n', 6)
                    shprint(prompt, prompt_color)
                    found = true
                    break
                end
            end
        end

        if not found then
            shprint(cmd[1]..' not found\n', 6)
            print_prompt()
        end
    else
        print_prompt()
    end
end

function receive_messages()
    local message = receive_message()

    if message then
        if message.input and type(message.input) == 'string' then
            return message.input
        end

        if message.tty then
            terminal_print("received tty message")

            send_message(tty, { enable = true })
        end

        if message.app_started then
        end

        if message.app_stopped then
            send_message(tty, { unsubscribe = message.app_stopped })
            send_message(tty, { subscribe = env.pid, name = name })
            send_message(tty, { enable = true })
            print_prompt()
        end
    end
end
