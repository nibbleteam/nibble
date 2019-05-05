-- NibUI->Text
-- Cria um objeto de texto que pode ter
-- váris características, como:
-- - Posição 
-- - Cor do FG
-- - Cor do BG
-- - Paleta
-- - Bold
-- - Underline

local Text = {}

function Text:new(text, x, y)
    local instance = {
        text = text or "",
        x = x or 0, y = y or 0,
        palette = 0,
        color = 15,
        background_color = 0,
        bold = 0,
        underline = false,
        align = 0
    }

    instanceof(instance, self)

    return instance
end

function Text:copy()
    local instance = {
        text = self.text,
        x = self.x, y = self.y,
        palette = self.palette,
        color = self.color,
        background_color = self.background_color,
        bold = self.bold,
        underline = self.underline,
        align = self.align
    }

    instanceof(instance, Text)

    return instance
end

function Text:set(key, value)
    self[key] = value or true

    return self
end

-- Troca as cores do FG e BG
function Text:swap_colors()
    local buffer = self.color
    self.color = self.background_color
    self.background_color = buffer

    return self
end

-- Returns a substring with the same
-- decorations
function Text:sub(i, j)
    local instance = {
        text = self.text:sub(i, j),
        x = self.x, y = self.y,
        palette = self.palette,
        color = self.color,
        background_color = self.background_color,
        bold = self.bold,
        underline = self.underline,
        align = self.align
    }

    instanceof(instance, Text)

    return instance
end

function Text:draw()
    local off_x = 0

    if self.align == 1 then
        off_x = -(#self.text*8)/2
    elseif self.align == 2 then
        off_x = -#self.text*8
    end
    
    -- Configura cores do FG e BG
    swap_colors(15, self.color)
    swap_colors(0, self.background_color)

    -- Configura bold/não bold
    swap_colors(7, self.bold)

    -- Desenha
    print(self.text, self.x+off_x, self.y, self.palette)

    -- Desenha underline
    if self.underline then
        local depth = 1

        if self.bold ~= 0 then
            depth = 2
        end

        fill_rect(self.x+off_x, self.y+9, #self.text*8, depth, self.color)
    end

    -- Reseta cores
    swap_colors(15, 15)
    swap_colors(7, 7)
    swap_colors(0, 0)
end

return Text
