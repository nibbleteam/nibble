require 'tty.write'

function init()
  -- Enable tty
  send_message(env.shell, { tty = true })

  write_line("Type the name of the app you want to")
  write_line("start after the \"~\" prompt")

  write_line("") 

  write_line("For extra help, check out:")
  write_line("") 
  write_line("https://github.com/pongboy/nibble/")

  stop_app(0)
end


