function transparent(index)
    kernel.write(32+index*4+3, "\00")
end

function setcolor(index, color)
    kernel.write(32+index*4, color)
end

function copypalette(a, b)
    kernel.write(32+b*4*16, kernel.read(32+a*4*16, 4*16))
end

function route_draw_color(a, b)
    if b == nil then
        b = a
    end

    kernel.write(544+a, string.char(b));
end

function route_screen_color(a, b)
    if b == nil then
        b = a
    end

    kernel.write(544+128+a, string.char(b))
end
