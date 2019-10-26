local write_line = require 'tty.write_line'

function init()
  if #env.params > 1 then
    local file = io.open(env.params[2])

    if file then
      local content = file:read('*all')

      write_line(content)

      file:close()
    end
  end

  stop_app(0)
end