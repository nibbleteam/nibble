local tty

local name = 'shell.nib'
local prompt = "~"
local prompt_color = 9

sh = {
    path = {
        "apps/system/utilities/",
        "apps/user/demos/",
        "apps/user/creator/",
        "apps/user/",
    }
}

function shprint(str, bg)
    kernel.send(tty, { print = str, background = bg})
end

function print_prompt()
    shprint(prompt, prompt_color)
    shprint(' ')
end

function init()
    tty = tonumber(kernel.getenv('tty'))

    -- Avisa que quer receber mensagens com entrada do usuário
    kernel.send(tty, { subscribe = tonumber(kernel.getenv('pid')), name = name })

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

    for word in line:gmatch('%a+') do
        table.insert(words, word)
    end

    return words
end

function execute(cmd)
    cmd = parse(cmd)

    if #cmd > 0 then
        local found = false
        
        for _, search_path in ipairs(sh.path) do
            local path = search_path..cmd[1]..".nib"

            local child, err = kernel.exec(path, {})

            if child > 0 then
                kernel.kill(child)

                local monitor = kernel.exec("apps/system/core/monitor.nib", {
                    shell = kernel.getenv("pid"),
                    tty = kernel.getenv("tty"),
                    exec = path
                })

                kernel.send(tty, {unsubscribe=tonumber(kernel.getenv('pid'))})
                kernel.wait(monitor)
                
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
    local message = kernel.receive()

    if message then
        if message.input and type(message.input) == 'string' then
            return message.input
        end

        if message.app_started then
        end

        if message.app_stopped then
            kernel.send(tty, {unsubscribe=message.app_stopped})
            kernel.send(tty, {subscribe=tonumber(kernel.getenv('pid')), name = name})
            print_prompt()
        end
    end
end
