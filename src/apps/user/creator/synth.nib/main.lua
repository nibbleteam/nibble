local ch = 0

local OP1 = 0
local OP2 = 1
local OP3 = 2
local OP4 = 3
local OUT = 4

local CH1 = 0
local CH2 = 1
local CH3 = 2
local CH4 = 3
local CH5 = 5
local CH6 = 6
local CH7 = 7
local CH8 = 8

function channel(c)
    ch = c
end

function envelope(op, sustain, volume, a, d, s, r)
    local str = string.char(sustain)..string.char(volume)
    str = str..string.char(a)..string.char(d)..string.char(s)..string.char(r)
    
    kernel.write(154448+4+op*6, str)
end

function freqs(op1, op2, op3, op4)
    local str = string.char(op1)..string.char(op2)..string.char(op3)..string.char(op4)

    kernel.write(154448+64*ch, str)
end

function reverb(delay, feedback)
    local str = string.char(delay)..string.char(feedback)

    kernel.write(154448+64*ch+52, str)
end

function route(from, to, amplitude)
    kernel.write(154448+64*ch+28+from*5+to, string.char(amplitude))
end

function noteon(n)
    kernel.write(154448+64*ch+48, '\x01'..string.char(n));
end

function noteoff(n)
    kernel.write(154448+64*ch+50, '\x01'..string.char(n));
end

function init()
end

-- C3
local base = 39
local octs = 'zsxdcvgbhnjmq2w3er5t6y7ui9o0p'
local prevnote = nil

local white_keys = {
    [0] = true,
    [2] = true,
    [3] = true,
    [5] = true,
    [7] = true,
    [8] = true,
    [10] = true,
}

local shownote = 0

-- 60Hz, real time
function audio_tick()
    local input = kernel.read(154410, 1)

    if input ~= '' then
        -- Encontra a nota
        local n = octs:find(input)

        if n ~= nil then
            n += base-1

            -- Primeiro canal
            channel(CH1)
            -- Frequência = nota para o primeiro operador
            freqs(253, 130, 0, 0)
            -- Envelope do primeiro operador
            envelope(OP1, 0, 255, 1, 10, 128, 128)
            envelope(OP2, 0, 255, 1, 10, 128, 128)
            -- Roteia o primeiro operador para a saída
            route(OP1, OUT, 255)
            route(OP2, OP1, 30)
            -- Reverb
            reverb(16, 128)

            if prevnote and prevnote ~= n then
                noteoff(prevnote)
            end

            -- Toca
            noteon(n)
            shownote = 5

            prevnote = n
        end
    end
end

function is_white(k)
   return white_keys[k%12]
end

function is_black(k)
    return not is_white(k)
end

function draw()
    clr(1)

    local key_length = 60
    local key_width = 10
    local key_spc = 2

    local p = 0
    for i=1,#octs do
        if is_white(i-1+base) then
            local c = 15

            if i-1+base == prevnote and shownote > 0 then
                c = 14
                shownote -= 1
            end

            rectf(p*(key_width+key_spc), 0, key_width, key_length, c)
            p += 1
        end
    end

    p = 1/2
    for i=1,#octs do
        if is_black(i-1+base) then
            local c = 2

            if i-1+base == prevnote and shownote > 0 then
                c = 5
                shownote -= 1
            end

            rectf(p*(key_width+key_spc)-(key_width+key_spc)/2, 0, key_width, key_length/2, c)

            if is_white(i+base) and is_white(i+1+base) then
                p += 1
            else
                p += 1/2
            end
        else
            p += 1/2
        end
    end
end

function update(dt)
end
