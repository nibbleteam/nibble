require "tty"

function init()
  send_message(env.tty, { subscribe = env.pid, name = "NET" })

  write_line("NET")
  
  find_players("NET", 2)
end

function update(dt)
  if math.random(256) == 1 then
    local msg = receive_network_message()

    if msg then
      if type(msg) == "table" and msg.operation == "players_found" then
        write_line("PLAYERS FOUND")

        for _, p in ipairs(msg.players) do
          write_line(" > "..p[1])
        end
      elseif type(msg) == "string" then
        write_line("(??) "..msg)
      end
    end
  end
  
  msg = receive_message()
  
  if msg and msg.input then
    if msg.input == "exit" then
      stop_app(0)
    else
      send_network_message(msg.input)
    end
  end
end
