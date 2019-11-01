if env.shell then
  send_message(env.shell, {
    tty = true
  })
end

function write(str, bg)
  send_message(env.tty, {
    print = tostring(str),
    background = bg,
  })
end

function write_line(str, bg)
  write(tostring(str).."\n", bg)
end
