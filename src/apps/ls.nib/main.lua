function write(line)
  send_message(env.tty, {
    print = line .. "\n"
  })
end

function init()
  write(tostring(#env.params))

  if #env.params > 1 then
    write("Listing " .. env.params[2])
  end

  --for _, dirname in ipairs(dirnames) do
  --    local dirs = list_directory(dirname)

  --    local chars_in_line = 0

  --    for _, dir in ipairs(dirs) do
  --        local app = dir:match("(%w*)%.nib")

  --        if app then
  --            send_message(env.tty, { print = app, background = 2 })
  --            send_message(env.tty, { print = " " })

  --            chars_in_line += #app

  --            if chars_in_line >= 30 then
  --                chars_in_line = 0
  --                send_message(env.tty, { print = "\n" })
  --            end
  --        end
  --    end
  --end

  --send_message(env.tty, { print = "\n" })
end



