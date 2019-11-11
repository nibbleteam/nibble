local ffi = require('ffi')
local hw = {}

-- Definições das funções cpp

ffi.cdef [[
void free(void* ptr);

typedef struct LuaString {
    char* ptr;
    size_t len;
} LuaString;

size_t kernel_api_read(char*, const size_t, const size_t);
size_t kernel_api_write(const size_t, const size_t, const char*);

void kernel_api_load_spritesheet(const char*, size_t*, int*, int*);
void kernel_api_use_spritesheet(const size_t, const int, const int);

void gpu_api_clear(uint8_t);
void gpu_api_clip(int16_t, int16_t, int16_t, int16_t);

void gpu_api_sprite(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);

void gpu_api_rect_fill(int16_t, int16_t, int16_t, int16_t, uint8_t);
void gpu_api_tri_fill(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);
void gpu_api_circle_fill(int16_t, int16_t, int16_t, uint8_t);
void gpu_api_quad_fill(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);

void gpu_api_line(int16_t, int16_t, int16_t, int16_t, uint8_t);
void gpu_api_rect(int16_t, int16_t, int16_t, int16_t, uint8_t);
void gpu_api_tri(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);
void gpu_api_circle(int16_t, int16_t, int16_t, uint8_t);
void gpu_api_quad(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);

void gpu_api_set_cursor(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);

LuaString* api_list_files(const char*, size_t*, int*);
int api_create_directory(const char*);
int api_touch_file(const char*);
int api_create_file(const char*);

int gpu_start_capturing(const char*);
int gpu_stop_capturing();

void audio_enqueue_command(const uint64_t,
                           const uint8_t,
                           const uint8_t,
                           const uint8_t,
                           const uint8_t);
]]

-- Wrappers

function hw.write(to, str)
    return ffi.C.kernel_api_write(to, #str, str)
end

function hw.read(from, amount)
    local buffer = ffi.new('char[?]', amount)
    local read = ffi.C.kernel_api_read(buffer, from, amount)
    return ffi.string(buffer, read)
end

function hw.load_spritesheet(sheet)
    local ptr = ffi.new('size_t[1]')
    local w, h = ffi.new('int[1]'), ffi.new('int[1]')

    ffi.C.kernel_api_load_spritesheet(sheet, ptr, w, h)

    return tonumber(ptr[0]), tonumber(w[0]), tonumber(h[0])
end

function hw.use_spritesheet(ptr, w, h)
    ffi.C.kernel_api_use_spritesheet(ptr, w, h)
end

-- GPU

local DEFAULT_COLOR = 0x00
local DEFAULT_PAL   = 0x00
local PAL_NUM       = 0x08
local SPR_W         = 0x10
local SPR_H         = 0x10

function hw.spr(x, y, sprx, spry, pal)
    assert(x, "spr() needs a x value")
    assert(y, "spr() needs a y value")
    assert(sprx, "spr() needs a sprx value")
    assert(spry, "spr() needs a spry value")

    -- Paleta padrão
    pal = pal or DEFAULT_PAL 
    -- Garante que todos são inteiros e a paleta é entre 0-7
    x, y = math.floor(x), math.floor(y)
    sprx, spry = math.floor(sprx), math.floor(spry)
    pal = math.floor(pal)%PAL_NUM
    -- Sprites para pixels
    sprx, spry = sprx*SPR_W, spry*SPR_H

    -- Envia para a GPU
    ffi.C.gpu_api_sprite(sprx, spry, x, y, SPR_W, SPR_H, pal)
end

function hw.pspr(x, y, sx, sy, w, h, pal)
    assert(x, "pspr() needs a x value")
    assert(y, "pspr() needs a y value")
    assert(sx, "pspr() needs a sx value")
    assert(sy, "pspr() needs a sy value")
    assert(w, "pspr() needs a w value")
    assert(h, "pspr() needs a h value")

    pal = pal or DEFAULT_PAL
    x, y = math.floor(x), math.floor(y)
    sx, sy = math.floor(sx), math.floor(sy)
    pal = math.floor(pal)%PAL_NUM

    ffi.C.gpu_api_sprite(sx, sy, x, y, w, h, pal)
end

function hw.clip(x, y, w, h)
    ffi.C.gpu_api_clip(x, y, w, h)
end

function hw.set_cursor(x, y, w, h, hx, hy, pal)
    ffi.C.gpu_api_set_cursor(x, y, w or 16, h or 16, hx or 0, hy or 0, pal or 0)
end

function hw.line(x1, y1, x2, y2, color)
    assert(x1, "line() needs a x1 value")
    assert(y1, "line() needs a y1 value")
    assert(x2, "line() needs a x2 value")
    assert(y2, "line() needs a y2 value")

    color = color or DEFAULT_COLOR

    ffi.C.gpu_api_line(x1, y1, x2, y2, color)
end

function hw.rect_fill(x, y, w, h, color)
    assert(x, "rectf() needs a x value")
    assert(y, "rectf() needs a y value")
    assert(w, "rectf() needs a w value")
    assert(h, "rectf() needs a h value")

    color = color or DEFAULT_COLOR

    ffi.C.gpu_api_rect_fill(x, y, w, h, color)
end

function hw.circle_fill(x, y, r, color)
    assert(x, "circf() needs a x value")
    assert(y, "circf() needs a y value")
    assert(r, "circf() needs a r value")

    color = color or DEFAULT_COLOR

    ffi.C.gpu_api_circle_fill(x, y, r, color)
end

function hw.quad_fill(x1, y1, x2, y2, x3, y3, x4, y4, color)
    assert(x1, "quadf() needs a x1 value")
    assert(y1, "quadf() needs a y1 value")
    assert(x2, "quadf() needs a x2 value")
    assert(y2, "quadf() needs a y2 value")
    assert(x3, "quadf() needs a x3 value")
    assert(y3, "quadf() needs a y3 value")
    assert(x4, "quadf() needs a x4 value")
    assert(y4, "quadf() needs a y4 value")

    color = color or DEFAULT_COLOR

    ffi.C.gpu_api_quad_fill(x1, y1, x2, y2, x3, y3, x4, y4, color)
end

function hw.tri_fill(x1, y1, x2, y2, x3, y3, color)
    assert(x1, "quadf() needs a x1 value")
    assert(y1, "quadf() needs a y1 value")
    assert(x2, "quadf() needs a x2 value")
    assert(y2, "quadf() needs a y2 value")
    assert(x3, "quadf() needs a x3 value")
    assert(y3, "quadf() needs a y3 value")

    color = color or DEFAULT_COLOR

    ffi.C.gpu_api_tri_fill(x1, y1, x2, y2, x3, y3, color)
end

function hw.rect(x, y, w, h, color)
    assert(x, "rectf() needs a x value")
    assert(y, "rectf() needs a y value")
    assert(w, "rectf() needs a w value")
    assert(h, "rectf() needs a h value")

    color = color or DEFAULT_COLOR

    ffi.C.gpu_api_rect(x, y, w, h, color)
end

function hw.circle(x, y, r, color)
    assert(x, "circf() needs a x value")
    assert(y, "circf() needs a y value")
    assert(r, "circf() needs a r value")

    color = color or DEFAULT_COLOR

    ffi.C.gpu_api_circle(x, y, r, color)
end

function hw.quad(x1, y1, x2, y2, x3, y3, x4, y4, color)
    assert(x1, "quadf() needs a x1 value")
    assert(y1, "quadf() needs a y1 value")
    assert(x2, "quadf() needs a x2 value")
    assert(y2, "quadf() needs a y2 value")
    assert(x3, "quadf() needs a x3 value")
    assert(y3, "quadf() needs a y3 value")
    assert(x4, "quadf() needs a x4 value")
    assert(y4, "quadf() needs a y4 value")

    color = color or DEFAULT_COLOR

    ffi.C.gpu_api_quad(x1, y1, x2, y2, x3, y3, x4, y4, color)
end

function hw.tri(x1, y1, x2, y2, x3, y3, color)
    assert(x1, "quadf() needs a x1 value")
    assert(y1, "quadf() needs a y1 value")
    assert(x2, "quadf() needs a x2 value")
    assert(y2, "quadf() needs a y2 value")
    assert(x3, "quadf() needs a x3 value")
    assert(y3, "quadf() needs a y3 value")

    color = color or DEFAULT_COLOR

    ffi.C.gpu_api_tri(x1, y1, x2, y2, x3, y3, color)
end

function hw.clr(color)
    color = color or DEFAULT_COLOR

    color = math.floor(color)%128

    ffi.C.gpu_api_clear(color)
end

local DEFAULT_FT_W = 10
local DEFAULT_FT_H = 10
local DEFAULT_CH_W = 8
local DEFAULT_CH_H = 8
local DEFAULT_FT_CHARS = "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ.,!?abcdefghijklmnopqrstuvwxyz()[]<>{}\"\"'-_=\\/|&~*%@$#:;+"..string.char(1)..string.char(2)..string.char(3)..string.char(4)..string.char(5)..string.char(6)..string.char(7)..string.char(8)..string.char(9)..string.char(10)..string.char(11)..string.char(12)..string.char(13)..string.char(14)..string.char(15)..string.char(16)..string.char(17).." "

function hw.print(str, dstx, dsty, pal)
    assert(str, "print() needs a str value")
    assert(dstx, "print() needs a x value")
    assert(dsty, "print() needs a y value")

    for i=1,#str do
        local ch = str:sub(i, i)
        local index, _ = DEFAULT_FT_CHARS:find(ch, 1, true)

        if index ~= nil then
            local px = math.floor((index-1)%DEFAULT_FT_W)*DEFAULT_CH_W
            local py = math.floor((index-1)/DEFAULT_FT_W)*DEFAULT_CH_H

            hw.pspr(dstx, dsty, px, py, DEFAULT_CH_W, DEFAULT_CH_H, pal)
        end

        dstx = dstx+DEFAULT_CH_W
    end
end

function hw.measure(str)
    return #str*DEFAULT_CH_W
end

-- Funções customizadas

function hw.readn(p, bytes, n)
    n = n or 0

    if bytes == 0 then
        return 0
    else
        return hw.read(p, 1):byte()*math.pow(2, 8*n)+hw.readn(p+1, bytes-1, n+1)
    end
end

function hw.read64(p)
    return hw.readn(p, 8)
end

function hw.read32(p)
    local data = hw.read(p, 4)

    local value = data:byte(4)

    value = value + data:byte(3)*256 + data:byte(2)*256*256 + data.byte(1)*256*256*256
end

function hw.read16(p)
    local data = hw.read(p, 2)
    local value = data:byte(2)
    value = value+data:byte(1)*256
    return value
end

function hw.read8(p)
    return hw.read(p, 1):byte()
end

-- Sistema de arquivos

function hw.list(path)
    local c_len = ffi.new('size_t[1]')
    local c_ok = ffi.new('int[1]')

    local files_ptr = ffi.C.api_list_files(path, c_len, c_ok)

    local len = tonumber(c_len[0])
    local ok = (tonumber(c_ok[0])==0 and {false} or {true})[1];

    if true then
        local list = {}

        for i=0,len-1 do
            table.insert(list, ffi.string(files_ptr[i].ptr, files_ptr[i].len))
            ffi.C.free(files_ptr[i].ptr)
        end

        ffi.C.free(files_ptr)

        return list
    else
        return nil
    end
end

function hw.create_directory(path)
    return ffi.C.api_create_directory(path) == 1
end

function hw.touch_file(path)
    return ffi.C.api_touch_file(path) == 1
end

function hw.create_file(path)
    return ffi.C.api_create_file(path) == 1
end

function hw.start_capturing(path)
    return ffi.C.gpu_start_capturing(path) == 1
end

function hw.stop_capturing()
    return ffi.C.gpu_stop_capturing() == 1
end

function hw.enqueue_command(t, ch, cmd, note, intensity)
    ffi.C.audio_enqueue_command(t, ch, cmd, note, intensity)
end

return hw

