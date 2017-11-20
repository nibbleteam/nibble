w, h = 320, 240
x, y = w/2, h/2
vx, vy = 1, 1
color = 1

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
	if math.random() > 0.9 then
		local d = directions[1+math.floor(math.random()*8)]
		vx, vy = d[1], d[2]
	end

	-- Muda de cor
	if math.random() > 0.9 then
		-- Tudo menos preto
		color = math.floor(math.random()*16) % 15 + 1
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
	kernel.write(x+y*w, string.char(color))
end
