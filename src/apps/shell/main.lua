function update()
end

function draw()
	for x=0,320,4 do
		for y=0,240,4 do
			local byte = string.char(math.floor(math.random()*255))
			kernel.write(y*320+x, byte);
		end
	end
end
