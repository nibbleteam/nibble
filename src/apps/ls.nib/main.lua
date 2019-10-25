require 'tty.write'

function init()
  send_message(env.shell, { tty = true })

  local dir = "." 

  if #env.params > 1 then
    dir = env.params[2]
  end
  
  local files = list_directory(dir)

  for _, file in ipairs(files) do
    local is_self = file:match("/%.%.")
    local is_parent = file:match("/%.") 

    if not (is_self or is_parent) then
      write_line(file)
    end 
  end

  stop_app(0) 
end
