require 'lang.timeout'

local SCREEN_W = 400
local SCREEN_H = 240

local BOOT_ANIM_W = 64
local BOOT_ANIM_H = 64

local SHEET_W = 8

local FRAMES = 32

local SPEED = 12

local SKIP_INTRO = true

function play()
  channel(CH1)

  freqs(1.0, 4.0, 1.0, 1.0)

  envelope(OP1, 0, 1, 0, 0.2, 0.1, 1.5, 0)
  envelope(OP2, 0, 1, 0, 0.2, 0.1, 1.0, 0)

  route(OP2, OP1, 1.0)
  route(OP1, OUT, 1.0)

  local notes = { 32, 33, 35, 33, 35, 37, 39, 40 }

  for i=1,8 do
    set_timeout(i/2, function()
      noteon(notes[i]+12, 128)
    end)
  end

  reverb(8, 0.5)
end

function init()
  --play()
end

function run_app()
    -- Start the shell
    local tty = start_app("apps/system/terminal.nib", {})
    start_app("apps/system/shell.nib", { tty = tty })

    -- Close the app
    stop_app(0)
end

function update(dt)
    if SKIP_INTRO then
        run_app()
    else
        if clock() > (FRAMES*3/2)/SPEED then
            for i=0,15 do
                swap_colors(i, i)
            end

            run_app()
        end
    end

    run_timeouts(dt)
end

function draw()
    local time = math.floor(clock()*SPEED)
    local frame = math.min(time, FRAMES-1)

    local x, y = frame%SHEET_W*BOOT_ANIM_H, math.floor(frame/SHEET_W)*BOOT_ANIM_H

    if time >= FRAMES+8 then
      local offset = (time-frame-8)*3

        if offset <= 16 then
            for i=offset,15 do
                swap_colors(i, i-(offset-1))
            end
        end
    end

    clear(0)

    if clock() <= (FRAMES*3/2)/SPEED then
      custom_sprite((SCREEN_W-BOOT_ANIM_W)/2, (SCREEN_H-BOOT_ANIM_H)/2, x, y, BOOT_ANIM_W, BOOT_ANIM_H, 0)
    end
end
