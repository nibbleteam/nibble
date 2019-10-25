-- new.nib

function tty_print(str)
    send_message(env.tty, { print = str })
end

function enable_tty()
    send_message(env.shell, { tty = true })
end

function make_directory(directory)
    tty_print("[DIR] ")
    tty_print(directory)
    tty_print("\n")

    create_directory(directory)
end

function make_file(file)
    tty_print("[FILE] ")
    tty_print(file)
    tty_print("\n")

    create_file(file)
end

function copy_file(from, to)
  local original = io.open(from, "r")

  if original then
    local content = original:read("*all")

    if content then
      make_file(to)
      
      local destination = io.open(to, "w")

      if destination then
        destination:write(content)

        io.close(destination)
      end
    end

    io.close(original)
  end
end

function init()
  enable_tty()

  local app_name = env.params[2]

  local src_sheet = "apps/system/terminal.nib/assets/sheet.png"
  local dir = "apps/"..app_name..".nib"
  local assets = dir .. "/" .. "assets"
  local main = dir.."/".."main.lua"
  local sheet = assets.."/".."sheet.png"

  make_directory(dir)
  make_directory(assets)
  make_file(main)
  copy_file(src_sheet, sheet)

  stop_app(0)
end
