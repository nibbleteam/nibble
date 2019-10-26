require 'tty.tty'

return function(str, bg_color)
  send_message(env.tty, {
    print = tostring(str),
    background = bg_color
  })
end