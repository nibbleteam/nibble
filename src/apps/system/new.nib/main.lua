require 'tty'

function make_directory(directory)
    write("[DIR] ")
    write(directory)
    write("\n")

    create_directory(directory)
end

function make_file(file)
    write("[FILE] ")
    write(file)
    write("\n")

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
