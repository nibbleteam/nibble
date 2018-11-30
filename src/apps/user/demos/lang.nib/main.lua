function init()
    shell = tonumber(kernel.getenv("shell"))

    local x = 0

    x += 1

    kernel.send(shell, {print=tostring(x)})

    kernel.kill(0)
end

function update()
end

function draw()
end
