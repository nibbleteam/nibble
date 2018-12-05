local tty

prompt = '>'
local more_prompt = '>>'
local input = ''
local prompt_color = 11

function shprint(str, bg)
    kernel.send(tty, { print = str, background = bg})
end

function init()
    tty = tonumber(kernel.getenv('tty'))

    kernel.send(tty, { subscribe = tonumber(kernel.getenv('pid')), name = 'lua.nib' })

    shprint(_VERSION..'\n', 6)
    shprint(prompt, prompt_color)
    shprint(' ')

    start_recording('lua.gif')
end

local more_input = false

function update()
    local message = kernel.receive()

    if message then
        if message.input then
            local fn, err = load('return (' .. input..message.input .. ')')

            if message.input == 'exit' or message.input == 'quit' then
                kernel.kill(0)
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
