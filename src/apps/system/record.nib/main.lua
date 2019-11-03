-- Inicia ou para a captura de tela

function init()
  send_message(env.shell, { tty = true })
  
  if #env.params > 1 then
    if env.params[2] == "stop" then
      stop_recording()
    else
      start_recording(env.params[2])
    end
  end

  stop_app(0)
end