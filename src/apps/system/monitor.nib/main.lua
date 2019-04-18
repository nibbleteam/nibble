local tty
local exec
local child
local shell

function init()
    tty = tonumber(kernel.getenv("tty"))
    exec = kernel.getenv("exec")
    shell = tonumber(kernel.getenv("shell"))

    child = kernel.exec(exec, {
        tty = tostring(tty)
    })

    if child > 0 then
        kernel.send(tty, {app_started=child, app_name=exec})
        kernel.wait(child)
    else
        kernel.send(shell, {app_stopped=child})
        kernel.kill(0)
    end
end

function update()
    kernel.send(shell, {app_stopped=child})
    kernel.kill(0)
end

function draw()
end
