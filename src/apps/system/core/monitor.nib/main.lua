local shell
local exec
local child

function init()
    shell = tonumber(kernel.getenv("shell"))
    exec = kernel.getenv("exec")

    child = kernel.exec(exec, {
        shell = tostring(shell)
    })

    if child > 0 then
        kernel.send(shell, {app_started=child, app_name=exec})
        kernel.wait(child)
    else
        kernel.kill(0)
    end
end

function update()
    kernel.send(shell, {app_stopped=child})
    kernel.kill(0)
end

function draw()
end
