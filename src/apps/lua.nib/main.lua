local tty

prompt = '>'
local more_prompt = '>>'
local input = ''
local prompt_color = 11

function shprint(str, bg)
    send_message(env.tty, { print = str, background = bg})
end

function init()
    send_message(env.shell, { tty = true })
    send_message(env.tty, { subscribe = env.pid, name = 'lua.nib' })

    shprint(_VERSION..'\n', 6)
    shprint(prompt, prompt_color)
    shprint(' ')
end

local more_input = false

function update()
    local message = receive_message()

    if message then
        if message.input then
            local fn, err = load('return (' .. input..message.input .. ')')

            if message.input == 'exit' or message.input == 'quit' then
                stop_app(0)
                return
            end

            if err then
                fn, err = load(input..message.input)
            end

            if err then
                -- Checa se precisamos de mais entrada
                if err:find('<eof>') then
                    more_input = true
                end
            end

            if #message.input == 0 then
                more_input = false
            end

            if more_input and err then
                input = input..message.input..'\n'
                shprint(more_prompt, prompt_color)
                shprint(' ')
                return
            end

            if err then
                shprint(err..'\n', 6)
                input = ''
            else
                local ok, ret = pcall(fn)
                shprint(tostring(ret)..'\n', 2)
                input = ''
            end

            shprint(prompt, prompt_color)
            shprint(' ')
        end
    end
end
