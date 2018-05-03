w, h = 320, 240
x, y = w/2, h/2
vx, vy = 0, 0 
color = 1 
vidstart = 8*16*4+32
pal = 0

directions = {
	{0, 1},
	{1, 1},
	{1, 0},
	{1, -1},
	{0, -1},
	{-1, -1},
	{-1, 0},
	{-1, 1},
}

direction = 1
counter = 0

function init()
   newpalette() 
end

function set_new_direction()
    for d=1,#directions do
        if directions[d][1] == vx and directions[d][2] == vy then
            direction = d
            break
        end
    end
end

function _update()
    counter = counter -1
	-- Muda de direção
	if counter < 0 then
        counter = 100*math.random()
        if x > 0 and x < w and y > 0 and y < h then
            if math.random() > 0.5 then
                direction = direction-1
            else
                direction = direction+1
            end
            
            if direction > #directions then
                direction = 1
            end

            if direction < 1 then
                direction = #directions
            end

            local d = directions[direction]
            vx, vy = d[1], d[2]
        end
	end

	-- Muda de cor
	if math.random() > 0.95 then
		-- Tudo menos preto
		color = math.floor(math.random()*14)+1
	end

	-- Move
	x = x+vx
	y = y+vy

	-- Atravessa nas bordas
	--if x <= 0 then
    --    x = w-1
    --end
    --if x >= w then
    --    x = 1
	--end

	--if y <= 0 then
    --    y = h-1
    --end
    --if y >= h then
    --    y = 1
	--end

    -- Bate nas bordas
    if x <= 0 or x >= w then
        vx = vx*-1

        set_new_direction()
        pal = math.floor(math.random()*16)
    end
    if y <= 0 or y >= h then
        vy = vy*-1

        set_new_direction()
        pal = math.floor(math.random()*16)
    end
end

function randbyte()
    return math.floor(math.random()*255)
end

function update()
end

function newpalette()
    -- Cria 7 novas paleta aleatória mas com preto no início de todas
    for j=1,7 do
        kernel.write(32+j*4*16, string.char(0x00, 0x00, 0x00, 0xFF))
        for i=1,15 do
            kernel.write(32+i*4+j*4*16, string.char(math.floor(randbyte()/2+128), randbyte(), randbyte(), 0xFF))
        end
    end
end

function i16(x)
    return string.char(math.floor(x/256), x%256)
end

local p = 0
local t = 0
function draw()
    t = t+0.017
    -- Limpa a tela
    --kernel.write(0, '\00\01')

    -- Rect na gpu
    -- 01 - Rect
    -- 00 - color
    -- 00 00 - x
    -- 00 00 - y
    -- 00 0A - w
    -- 00 0A - h
    local gx, gy
    gx = math.floor(math.cos(t*4)*100+100)+50
    gy = math.floor(math.sin(t*4)*100+100)+20
    kernel.write(0, string.char(0x01, 0x02, math.floor(gx/256), gx%256, math.floor(gy/256), gy%256, 0x00, 0x8, 0x00, 0x8));


    -- Apaga aleatoriamente
    for i=1,200 do
        local position = math.floor(320*240*math.random());
        kernel.write(vidstart+position, '\0\0\0')
        kernel.write(vidstart+position+320, '\0\0\0')
        kernel.write(vidstart+position+640, '\0\0\0')
    end

    -- Triângulo
    kernel.write(0, '\03\03'..i16(160)..i16(30)..i16(60)..i16(210)..i16(260)..i16(210))

    for i=1,12 do
        _update()

        -- Desenha
        if x > 0 and x < w and y > 0 and y < h then
            putpix(x, y, color)
            putpix(x+1, y, color)
            putpix(x+1, y+1, color)
            putpix(x, y+1, color)
        end
    end

    --kernel.write(0, string.char(0x01, 0x01, 0x01, 320%256-0x30, 0x00, 240-0x30, 0x00, 0x30, 0x00, 0x30));
end

function putpix(x, y, color)
    local position = y*w+x
    kernel.write(vidstart+math.floor(position), string.char(color))
end
