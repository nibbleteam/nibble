function init()
    --kernel.exec("apps/system/core/shell.nib", {})
    kernel.exec("apps/user/creator/music.nib", {})
    kernel.kill(0)
end
