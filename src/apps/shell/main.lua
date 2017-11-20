function update()
end

function draw()
	for x=0,320,2 do
		for y=0,240,2 do
			local byte = string.char(math.floor(math.random()*255))
			kernel.write(y*320+x, byte);
		end
	end
end
