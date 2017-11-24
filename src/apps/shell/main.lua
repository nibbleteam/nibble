w, h = 320, 240
x, y = w/2, h/2
vx, vy = 0, 0 
color = 1 
vidstart = 8*16*4
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

math.randomseed(os.time())

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
    -- Cria 8 novas paleta aleatória mas com preto no início de todas
    for j=0,7 do
        kernel.write(j*4*16, string.char(0x00, 0x00, 0x00, 0xFF))
        for i=1,15 do
            kernel.write(i*4+j*4*16, string.char(math.floor(randbyte()/2+128), randbyte(), randbyte(), 0xFF))
        end
    end
end

local p = 0
function draw()
    for i=1,16 do
        _update()

        -- Desenha
        if x > 0 and x < w and y > 0 and y < h then
            putpix(x, y, color)
        end

        -- Apaga aleatoriamente
        for i=1,32 do
            local position = math.floor(320*240*math.random());
            -- Um write evitando muitas drawcalls
            kernel.write(vidstart+position, '\0\0\0')
            kernel.write(vidstart+position+240, '\0\0\0')
            kernel.write(vidstart+position+240, '\0\0\0')
        end
    end
end

function putpix(x, y, color)
    local position = y*w+x
    kernel.write(vidstart+math.floor(position), string.char(color))
end
