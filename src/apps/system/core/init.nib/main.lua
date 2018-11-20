function init()
    local x = 1
    local y = {
        y = 1
    }
    local z = {
        z = {
            z = 1
        }
    }

    x += 1
    y.y += 1
    z.z.z += 1

    dprint(x)
    dprint(y.y)
    dprint(z.z.z)

    kernel.exec("apps/system/core/shell.nib", {})
    kernel.kill(0)
end
