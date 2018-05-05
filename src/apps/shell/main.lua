local beep = 0 
local lines = {}
local prompt = ": "
local input_line = prompt
local children = {}

local note = 0
function audio_tick(channel)
    local channel_conf = "\00\00\00\00"

    if channel == 0 then
        if beep > 0 then
            beep = beep-1

            if beep > 5 then
                note = math.floor((20-beep)/5)*3
            end

            channel_conf = "\01\255\03"..string.char(note)
        end
    end

    kernel.write(154192+channel*4, channel_conf)
end

function init()
    -- Deixa a cor 0 na paleta 0 transparente
    kernel.write(0x20+3, '\0')

    add_line("Nibble Shell")
    add_line("v1")
    add_line("")
end

local blink = 0

function draw()
  clr(0)

  for l=#lines,1,-1 do
      print(lines[l], 0, (l-1)*10)
  end

  print(input_line, 0, (#lines)*10)

  if blink > 0 then
      rectf(#input_line*8, (#lines)*10+1, 2, 8, 15)
  end

  if blink < -20 then
      blink = 20
  end

  blink = blink - 1
end

function add_line(line)
    table.insert(lines, line)

    if #lines > 23 then
        table.remove(lines, 1)
    end

    beep = 20
end

function update()
  if kernel.getenv("menu.entry") == "back" then
      add_line("NOTE: menu was called")
      kernel.setenv("menu.entry", "")
  end

  local keys = kernel.read(0x25A2a, 1)

  local message = kernel.receive()

    if message then
        if message.print and type(message.print) == "string" then
          add_line(message.print)
        end

        if message.app_started then
            children[message.app_started] = message.app_name
        end

        if message.app_stopped then
            children[message.app_stopped] = nil
        end
    end

  if #keys > 0 then
    blink = 20

    -- Backspace
    if keys == "\8" then
      if #input_line > prompt:len() then
        input_line = input_line:sub(1, #input_line-1)
      end
    -- CTRL-C
    elseif keys == "\03" then
        local highestpid = 0
        local name = ""
        for k, v in pairs(children) do
            if k > highestpid then
                highestpid = k
                name = v
            end
        end

        if highestpid ~= 0 then
            kernel.kill(highestpid)
            children[highestpid] = nil

            add_line("closing "..name)
        end
    -- Enter
    elseif keys == "\13" then
        local cmd = {}
        
        for part in input_line:sub(prompt:len()+1, #input_line):gmatch("%S+") do
            table.insert(cmd, part)
        end

        if #cmd > 0 then
            if cmd[1] == "exit" then
                kernel.kill(0)
            elseif cmd[#cmd] == "&" then
                local child = kernel.exec("apps/system/monitor", {
                    shell = kernel.getenv("pid"),
                    exec = cmd[1]
                })
                input_line = prompt
                
                if child <= 0 then
                    add_line("ERROR: invalid cartridge!")
                else
                end
            else
                local child = kernel.exec(cmd[1], {shell = kernel.getenv("pid")})
                add_line(input_line)
                input_line = prompt
                
                if child > 0 then
                    kernel.wait(child)
                else
                    local child = kernel.exec("apps/system/monitor", {
                        shell = kernel.getenv("pid"),
                        exec = system(cmd[1])
                    })
                    --add_line(input_line)
                    input_line = prompt
                    
                    if child > 0 then
                    else
                        add_line("ERROR: invalid cartridge!")
                    end
                end
            end
        end
    else
      input_line = input_line..keys
    end
  end
end

function system(path)
    return "apps/system/"..path
end
