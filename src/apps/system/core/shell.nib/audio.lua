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

local t = 0

local c0a0 = 255
local c0 = {48, 51, 50, 55, 53, 56, 55, 53, 51, 50};
local p0 = 15

local c1a0 = 250
local c1 = {12, 14, 15, 15, 14, 14, 12, 14};
local p1 = 30

function audio_tick()
    if audio_enable then
        if t%30 == 0 then
            -- Frequencies
            kernel.write(154448, '\xff\x80')
            -- No sustain + envelopes
            kernel.write(154448+4, '\x00\xc0\x01\x01\x60\x01')
            kernel.write(154448+10, '\x00\xc0\x01\x01\x60\x01')
            -- Routing table
            kernel.write(154448+4+4*6+0*5+1, string.char(60))
            kernel.write(154448+4+4*6+1*5+4, string.char(255))

            -- A4, note on
            kernel.write(154448+48, '\x01\x30');
        end

        if t%p0 == 0 and t > 60 then
            -- Frequencies
            kernel.write(154448+64, '\x80'..string.char(c0a0))
            -- No sustain + envelopes
            kernel.write(154448+4+64, '\x00\xff\x80\x01\x80\x01')
            kernel.write(154448+10+64, '\x00\xff\x40\x01\x80\x01')
            -- Routing table
            kernel.write(154448+4+4*6+0*5+1+64, string.char(60))
            kernel.write(154448+4+4*6+1*5+4+64, string.char(255))

            local p = math.floor(t/p0)%#c0+1

            -- note on
            kernel.write(154448+64+48, '\x01'..string.char(c0[p]));

            if p == #c0 then
                for i=1,#c0 do
                    if c0[i] >= 48 then
                        c0[i] = c0[i]-12
                    end

                    if c0a0 > 128 then
                        c0a0 = 128
                        p0 = 30
                    end
                end
            end
        end

        if t%p1 == 0 and t > 120 then
            -- Frequencies
            kernel.write(154448+2*64, '\x80'..string.char(c1a0))
            -- No sustain + envelopes
            kernel.write(154448+4+2*64, '\x00\xff\x25\x50\x80\x10')
            kernel.write(154448+10+2*64, '\x00\xff\x05\x20\xb0\x01')
            -- Routing table
            kernel.write(154448+4+4*6+0*5+1+2*64, string.char(60))
            kernel.write(154448+4+4*6+1*5+4+2*64, string.char(255))

            local p = math.floor(t/p1)%#c1+1

            -- note on
            kernel.write(154448+2*64+48, '\x01'..string.char(c1[p]));
        end

        t += 1
    end
end
