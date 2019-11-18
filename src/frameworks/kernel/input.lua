local hw = require 'frameworks.kernel.hw'
local input = {}

-- 320x240
--input.MIDI_CONTROLLER   = 78456
--input.CONTROLLER        = 78408
--input.KEYBOARD          = 78418
--input.MOUSE             = 78450
-- 400x240
input.MIDI_CONTROLLER   = 97690
input.CONTROLLER        = 97608
input.KEYBOARD          = 97618
input.KEYBOARD_EVENTS   = 97650
input.MOUSE             = 97682

input.STUP       = 0
input.STPRESSED  = 1
input.STDOWN     = 2
input.STRELEASED = 3

input.UP    = 0
input.RIGHT = 1
input.DOWN  = 2
input.LEFT  = 3

input.RED   = 4
input.BLUE  = 5

input.BLACK = 6
input.WHITE = 7

input.MOUSE_LEFT  = 0
input.MOUSE_RIGHT = 1

input.SHIFT = 1
input.CTRL  = 2
input.ALT   = 3
input.GUI   = 4

function input.bt(b)
  assert(b, "bt() needs a button")

  b = math.floor(b)%8

  local value;

  if b < 4 then
    value = hw.read(input.CONTROLLER+1, 1):byte()
  else
    value = hw.read(input.CONTROLLER+2, 1):byte()
  end

  if b%4 == input.UP then
    return math.floor(value/64)
  elseif b%4 == input.RIGHT then
    return math.floor((value-math.floor(value/64)*64)/16)
  elseif b%4 == input.DOWN then
    return math.floor((value-math.floor(value/16)*16)/4)
  elseif b%4 == input.LEFT then
    return value-math.floor(value/4)*4
  end
end

input.button_down = function (b) return input.bt(b) == input.STDOWN; end
input.button_up = function (b) return input.bt(b) == input.STUP; end
input.button_press = function (b) return input.bt(b) == input.STPRESSED; end
input.button_release = function (b) return input.bt(b) == input.STRELEASED; end

function input.has_mouse() return true end
function input.has_keyboard() return true end

function input.mouse_position()
    return hw.read16(input.MOUSE), hw.read16(input.MOUSE+2)
end

function input.mouse_button(b)
    return hw.read8(input.MOUSE+4+b)
end

function input.mouse_scroll()
  local x, y = hw.read8(input.MOUSE+6), hw.read8(input.MOUSE+7)

  return (x-128), (y-128)
end

function input.mouse_button_down(b) return input.mouse_button(b) == input.STDOWN end
function input.mouse_button_up(b) return input.mouse_button(b) == input.STUP end
function input.mouse_button_press(b) return input.mouse_button(b) == input.STPRESSED end
function input.mouse_button_release(b) return input.mouse_button(b) == input.STRELEASED end

function input.read_keys()
    local amount = hw.read8(input.KEYBOARD)

    if amount == 0 then
        return ""
    end

    return hw.read(input.KEYBOARD+1, amount)
end

function input.read_key_events()
  local events = {}
  local i = 0

  while i < 32 do
    local kind = hw.read8(input.KEYBOARD_EVENTS+i)

    if kind == 0 then
      break
    end

    local key = hw.read8(input.KEYBOARD_EVENTS+i+1)
    local mods = hw.read8(input.KEYBOARD_EVENTS+i+2)

    table.insert(events, {
                   kind, key, mods
    })

    i += 3
  end

  return events
end

function input.read_midi()
    local cmds = {}

    local ptr = input.MIDI_CONTROLLER

    while true do
        local amount = hw.read8(ptr)

        if amount > 0 then
            local cmd = {}

            for i=1,amount do
                table.insert(cmd, hw.read8(ptr+i))
                hw.write(ptr+i, '\00')
            end

            table.insert(cmds, cmd)

            ptr += amount+1
        else
            break
        end
    end

    return cmds
end

return input
