function init()
    -- Deixa a cor 0 na paleta 0 transparente
    kernel.write(0x20+3, '\0')
end

function draw()
    spr(0, 0, 0, 0)
end

function update()
end
