w, h = 320, 240
x, y = w/2, h/2
vx, vy = 0, 0 
color = {0, 0, 0}

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

function update()
    counter = counter -1
	-- Muda de direção
	if counter < 0 then
        counter = 50
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

	-- "Bate" nas bordas
	if x <= 0 then
        x = w-1
    end
    if x >= w then
        x = 1
	end

	if y <= 0 then
        y = h-1
    end
    if y >= h then
        y = 1
	end
end

function draw()
	-- Desenha
    putpix(x, y, color[1])

    -- Apaga aleatoriamente
    for i=1,32 do
        kernel.write(math.floor(320/2*240*math.random()), '\0')
    end
end

function putpix(x, y, color)
    color = color%16
    local position = y*320+x
    local pixel = kernel.read(math.floor(position/2), 1):byte()

    if not pixel then
        pixel = 0
    end

    if position%2 == 0 then
        pixel = pixel-math.floor(pixel/16)*16 + math.floor(color)*16
    else
        pixel = math.floor(pixel/16)*16+color
    end

    kernel.write(math.floor(position/2), string.char(pixel))
end
