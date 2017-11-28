function init()
    -- Deixa a cor 0 na paleta 0 transparente
    kernel.write(0x20+3, '\0')
end

function draw()
    spr(0, 0, 0, 0)
    kernel.write(0x220, kernel.read(0x12E20, 320*240))
end

function update()
end
