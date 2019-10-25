env.menu = {
  "Hello"
}

function enable_tty()
  send_message(env.shell, {
    tty = true
  })
end

function capture_tty(name)
  send_message(env.tty, {
    subscribe = env.pid,
    name = name
  })
end

function write(str)
  send_message(env.tty, {
    print = str
  })
end

function init()
  enable_tty()
  capture_tty("Type a number")
  
  write("Hello!\n")
  write("This is a simple nibble app\n")
end

function calculate_and_exit(n)
  write(tostring(n*n) .. "\n")

  stop_app(0)
end

function update(dt)
  local message = receive_message()

  if message and message.input then
    terminal_pretty(message)

    calculate_and_exit(
      tonumber(message.input)
    )
  end
end
