local t = 0
local bass = 0
local ch = {
    0, 0, 0, 0, 0, 0, 0
}

function audio_tick(channel)
    if channel == 0 then
        t = t+1/60
        bass = bass+1

        local base = {0, 3, 0, 2}
        base = base[math.floor(bass/30)%#base+1]

        if bass%30 < 20 then
            kernel.write(154192, makeaudio(1, 128, 2, base))
            ch[1] = ch[1]+1
        else
            kernel.write(154192, makeaudio(0, 0, 0, 0))
        end

        if bass%30 > 25 then
            kernel.write(154192+20, makeaudio(0, 64, 2, 0))
            ch[5] = ch[5]+1
        elseif bass%30 > 20 then
            kernel.write(154192+20, makeaudio(0, 64, 2, 0))
            ch[5] = ch[5]+1
        else
            kernel.write(154192+20, makeaudio(0, 0, 0, 0))
        end

        if bass%120 < 30 then
            kernel.write(154192+4, makeaudio(3, 128, 3, 0))
            ch[2] = ch[2]+1
        else
            kernel.write(154192+4, makeaudio(0, 0, 0, 0))
        end

        base = {0, 0, 3, 0, 0, 3, 2, 0, 0, 5, 3, 5, 3, 8, 5, 3, 0, 0}
        base = base[math.floor(bass/30)%#base+1]

        kernel.write(154192+8, makeaudio(1, 32, 4, base))
        kernel.write(154192+12, makeaudio(2, 32, 3, base))
        ch[3] = 8+bass%8
        ch[4] = 8+bass%8
    end
end

function makeaudio(w, v, o, n)
    return string.char(w)..string.char(v)..string.char(o)..string.char(n)
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
