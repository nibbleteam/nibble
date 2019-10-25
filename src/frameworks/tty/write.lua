function write(str)
  send_message(env.tty, {
    print = tostring(str)
  })
end

function write_line(str)
  write(str .. "\n")
end
