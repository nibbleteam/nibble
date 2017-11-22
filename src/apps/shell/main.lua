w, h = 320, 240
x, y = w/2, h/2
vx, vy = 0, 0 
color = {0, 0, 0}
vidstart = 16*4

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

function set_new_direction()
    for d=1,#directions do
        if directions[d][1] == vx and directions[d][2] == vy then
            direction = d
            break
        end
    end
end

function update()
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
		color = {
            math.floor(math.random()*14)+1,
            math.floor(math.random()*14)+1,
            math.floor(math.random()*14)+1,
        }
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
        newpalette()
    end
    if y <= 0 or y >= h then
        vy = vy*-1

        set_new_direction()
        newpalette()
    end
end

function randbyte()
    return math.floor(math.random()*255)
end

function newpalette()
    -- Cria uma nova paleta aleatória mas com preto no início
    kernel.write(0, string.char(0x00, 0x00, 0x00, 0xFF))
    for i=1,15 do
        kernel.write(i*4, string.char(randbyte(), randbyte(), randbyte(), 0xFF))
    end
end

function draw()
    for i=1,10 do
        update()

        -- Desenha
        if x > 0 and x < w and y > 0 and y < h then
            putpix(x, y, color[1])
        end

        -- Apaga aleatoriamente
        for i=1,32 do
            kernel.write(vidstart+math.floor(320/2*240*math.random()), '\0')
        end
    end
end

function putpix(x, y, color)
    color = color%16
    local position = y*320+x
    local pixel = kernel.read(vidstart+math.floor(position/2), 1):byte()

    if position%2 == 0 then
        pixel = pixel-math.floor(pixel/16)*16 + math.floor(color)*16
    else
        pixel = math.floor(pixel/16)*16+color
    end

    kernel.write(vidstart+math.floor(position/2), string.char(pixel))
end
