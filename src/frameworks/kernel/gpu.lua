local hw = require('frameworks.kernel.hw')
local gpu = {}

function gpu.swap_colors(a, b)
    if b == nil then
        b = a
    end

    hw.write(512+a, string.char(b));
end

function gpu.swap_screen_colors(a, b)
    if b == nil then
        b = a
    end

    hw.write(512+128+a, string.char(b))
end

function gpu.mask_color(index)
    hw.write(index*4+3, "\00")
end

function gpu.rgba_color(index, color)
    hw.write(index*4, color)
end

function gpu.copy_palette(a, b)
    hw.write(b*4*16, hw.read(a*4*16, 4*16))
end

function gpu.put_pixel(x, y, color)
    assert(x, "putp() needs a x value")
    assert(y, "putp() needs a y value")
    assert(color, "putp() needs a color value")

    x = math.abs(math.floor(x))%400
    y = math.abs(math.floor(y))%240

    color = math.abs(math.floor(color))%128

    hw.write(y*400+x+768, string.char(color))
end

function gpu.get_pixel(x, y)
    assert(x, "getp() needs a x value")
    assert(y, "getp() needs a y value")

    x = math.abs(math.floor(x))%400
    y = math.abs(math.floor(y))%240

    return hw.read(y*400+x+768, 1):byte()
end

function gpu.get_sheet_pixel(sheet_location, sheet_w, sheet_h, x, y)
    x = math.abs(math.floor(x))%sheet_w
    y = math.abs(math.floor(y))%sheet_h

    return hw.read(y*sheet_w+x+sheet_location, 1):byte()
end

function gpu.put_sheet_pixel(sheet_location, sheet_w, sheet_h, x, y, color)
    x = math.abs(math.floor(x))%sheet_w
    y = math.abs(math.floor(y))%sheet_h

    return hw.write(y*sheet_w+x+sheet_location, string.char(color%128))
end

return gpu

