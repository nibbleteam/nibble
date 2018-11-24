-- NibUI->FormattedText
-- Cria um objeto de texto dentro
-- de uma bounding box em que
-- partes individuais podem receber
-- atributos diferentes
local FormattedText = {}

local DEFAULT_W = 320
local DEFAULT_H = 240
local CHAR_W = 8
local CHAR_H = 8

function FormattedText:new(x, y, w, h)
    local instance = {
        -- Bounding box
        x = x or 0, y = y or 0,
        w = w or DEFAULT_W,
        h = h or DEFAULT_H,
        -- Cursor (em caracteres)
        cursor = 0,
        cursor_x = x or 0,
        cursor_y = y or 0,
        -- Várias instâncias de DecoratedText
        text = {}
    }

    lang.instanceof(instance, self)

    return instance
end

function FormattedText:delete(n)
    while n > 0 do
        local deleted = self:try_delete(n)
        n -= deleted
        self.cursor -= deleted
    end

    local last = self.text[#self.text]

    self.cursor_x = last.x+#last.text*CHAR_W
    self.cursor_y = last.y
end

function FormattedText:try_delete(n)
    local deleted = 0
    local from = self.text[#self.text]
    
    if n < #from.text then
        from.text = from.text:sub(0, #from.text-n)

        return n
    else
        table.remove(self.text, #self.text)
        return #from.text
    end
end

function FormattedText:newline()
    self.cursor_x = self.x
    self.cursor_y += CHAR_H
end

function FormattedText:add(text)
    text.x, text.y = self.cursor_x, self.cursor_y
    text.align = 0

    local texts = self:advance_cursor(text)

    for _, text in ipairs(texts) do
        table.insert(self.text, text)
    end

    return self
end

function FormattedText:draw()
    for t=1,#self.text do
        self.text[t]:draw()
    end
end

function FormattedText:advance_cursor(text)
    local by = text.text
    local texts = {}

    self.cursor += #by

    self.cursor_x += #by*CHAR_W
    
    if self.cursor_x > self.x+self.w then
        local overflow = (self.cursor_x-(self.x+self.w))/CHAR_W

        self.cursor_x = self.x
        self.cursor_y += CHAR_H

        local before, after = text:sub(0, #by-overflow), text:sub(#by-overflow, #by)

        after.x = self.cursor_x
        after.y = self.cursor_y

        table.insert(texts, before)

        local nested_texts = self:advance_cursor(after)

        for _, text in ipairs(nested_texts) do
            table.insert(texts, text)
        end
    else
        table.insert(texts, text)
    end

    return texts
end

return FormattedText
