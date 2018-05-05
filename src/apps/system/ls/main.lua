local shell

function init()
    shell = tonumber(kernel.getenv("shell"))

    kernel.send(shell, {print="[DIR] [./]"})
    kernel.send(shell, {print="apps/"})

    kernel.kill(0)
end

function update()
end

function draw()
end
