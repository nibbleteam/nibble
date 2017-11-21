w, h = 320, 240
x, y = w/2, h/2
vx, vy = 0, 0 
color = {0, 0, 0}

directions = {
	{0, 1},
	{1, 0},
	{1, 1},
	{-1, 1},
	{-1, -1},
	{1, -1},
	{-1, 0},
	{0, -1},
}

function update()
	-- Muda de direção
	if math.random() > 0.95 then
        if x > 0 and x < w and y > 0 and y < h then
            local d = directions[1+math.floor(math.random()*8)]
            vx, vy = d[1], d[2]
        end
	end

	-- Muda de cor
	if math.random() > 0.95 then
		-- Tudo menos preto
		color = {
            math.floor(math.random()*255),
            math.floor(math.random()*255),
            math.floor(math.random()*255),
        }
	end

	-- Move
	x = x+vx
	y = y+vy

	-- "Bate" nas bordas
	if x <= 0 or x >= w then
		vx = vx*-1
	end
	if y <= 0 or y >= h then
		vy = vy*-1
	end
end

function draw()
	-- Desenha
    local brga = string.char(color[1])..string.char(color[2])..string.char(color[3])..string.char(255)
	kernel.write(math.floor(x+y*w), brga)

    -- Apaga aleatoriamente
    for i=1,320 do
        kernel.write(math.floor(320*240*math.random()), '\0\0\0'..string.char(255))
    end
end
