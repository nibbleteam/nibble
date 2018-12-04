local tty

function init()
    tty = tonumber(kernel.getenv("tty"))

    kernel.send(tty, {print="[DIR] [./]\n"})
    kernel.send(tty, {print="apps/\n"})

    kernel.kill(0)
end

function update()
end

function draw()
end
