function init()
    kernel.exec("apps/system/core/shell.nib", {})
    kernel.kill(0)
end
