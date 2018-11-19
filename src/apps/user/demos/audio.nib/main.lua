local bass = 0
local ch = {
    0, 0, 0, 0, 0, 0, 0, 0
}
local t = 0

local c0a0 = 64
local c0 = {48, 51, 50, 53, 55, 53, 50, 48, 50}
local p0 = 30

local c1a0 = 255
local c1 = {24, 26, 24, 27, 24, 26}
local p1 = 60

function audio_tick()
    if t%30 == 0 then
        -- Frequencies
        kernel.write(154448, '\xff\x80')
        -- No sustain + envelopes
        kernel.write(154448+4, '\x00\xc0\x01\x01\x60\x01')
        kernel.write(154448+10, '\x00\xc0\x01\x01\x60\x01')
        -- Routing table
        kernel.write(154448+4+4*6+0*5+1, string.char(60))
        kernel.write(154448+4+4*6+1*5+4, string.char(64))

        -- A4, note on
        kernel.write(154448+48, '\x01\x30');

        ch[1] = ch[1] + 1
    end

    if t%p0 == 0 and t > 60 then
        -- Frequencies
        kernel.write(154448+64, '\x80'..string.char(c0a0))
        -- No sustain + envelopes
        kernel.write(154448+4+64, '\x00\x10\x20\x01\x05\x20')
        kernel.write(154448+10+64, '\x00\xff\x80\x20\x80\x20')
        -- Routing table
        kernel.write(154448+4+4*6+0*5+1+64, string.char(60))
        kernel.write(154448+4+4*6+1*5+4+64, string.char(128))

        local p = math.floor(t/p0)%#c0+1

        -- note on
        kernel.write(154448+64+48, '\x01'..string.char(c0[p]));

        ch[2] = ch[2] + 1
    end

    if t%p1 == 0 and t > 120 then
        -- Frequencies
        kernel.write(154448+2*64, '\x80'..string.char(c1a0)..'\xff')
        -- No sustain + envelopes
        kernel.write(154448+4+2*64, '\x00\xff\x05\x50\x80\x80')
        kernel.write(154448+10+2*64, '\x00\xff\x01\x01\xb0\xff')
        kernel.write(154448+16+2*64, '\x00\xff\x01\x01\xb0\x80')
        -- Routing table
        kernel.write(154448+4+4*6+0*5+1+2*64, string.char(60))
        kernel.write(154448+4+4*6+1*5+4+2*64, string.char(40))
        kernel.write(154448+4+4*6+2*5+4+2*64, string.char(50))

        local p = math.floor(t/p1)%#c1+1

        -- note on
        kernel.write(154448+2*64+48, '\x01'..string.char(c1[p]));

        ch[3] = ch[3] + 1
    end

    t += 1
end

function init()
end

function update()
    for c=1,#ch do
        if ch[c] > 1 then
            ch[c] = ch[c] - 1.5
        end
    end
end

function draw()
    clr(math.floor(bass/30)%8)

    print("THE NIBBLE AUDIO DEMO - PRESENTING - UNAMED SHITTY SONG", (800-bass%800)-400, 122);

    for c=1,#ch do
        local x = c*15+95
        local y = 120-ch[c]*2 
        local w = 10
        local h = ch[c]*2

        rectf(x, y, w, h, 8+c)
        x = x-5
        w = 5
        quadf(x, y-5, x+w, y, x+w, y+h, x, y+h-5, c)
        w = 15
        quadf(x, y-5, x+w-5, y-5, x+w, y, x+5, y, c+7)
        print(tostring(c), c*15+95, 130)
    end
end
