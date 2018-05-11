-- Nibble Shell
-- Audio

local SQUARE = 0
local TRI = 1
local SAW = 2
local SIN = 3
local PSIN = 4

function makeaudio(w, v, o, n)
    return string.char(w)..string.char(v)..string.char(o)..string.char(n)
end

function audio_tick(c)
    kernel.write(154448+c*4, makeaudio(SQUARE, 0, 0, 0))
end
