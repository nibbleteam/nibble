local tty

function init()
    tty = tonumber(kernel.getenv("tty"))

    local dirname = 'apps/user/creator/';

    kernel.send(tty, {print="[DIR] ["..dirname.."]\n"})

    local dirs = kernel.list(dirname)

    for _, dir in ipairs(dirs) do
        kernel.send(tty, {print=dir.."\n"})
    end

    kernel.kill(0)
end

function update()
end

function draw()
end
