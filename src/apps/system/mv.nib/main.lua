function move_file(from, to)
  local f_from = io.open(from, 'rb')

  if f_from then
    local content = f_from:read('*all')

    if content then
      local f_to = io.open(to, 'wb')

      f_to:write(content)

      f_to:close()
    end

    f_from:close()

    -- Deleta o arquivo
    os.remove(from)
  end
end

function init()
  if #env.params > 2 then
    local from = env.params[2]
    local to = env.params[3]

    move_file(from, to)
  end

  stop_app(0)
end
