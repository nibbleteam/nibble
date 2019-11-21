function init()
  send_message(env.taskbar, {
    kind = "set_menu",
    menu = {
      color = 13,
      items = {}
    }
  })
end

function draw()
  clear(13)
end
