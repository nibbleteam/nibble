-- NibUI->Textarea
-- Cria um objeto de texto dentro
-- de uma bounding box em que
-- partes individuais podem receber
-- atributos diferentes
local Textarea = {}

local DEFAULT_W = 320
local DEFAULT_H = 240
local CHAR_W = 8
local CHAR_H = 8

function Textarea:new(x, y, w, h)
    local instance = {
        -- Bounding box
        x = x or 0, y = y or 0,
        w = w or DEFAULT_W,
        h = h or DEFAULT_H,
        -- Cursor (em caracteres)
        cursor = 0,
        cursor_x = x or 0,
        cursor_y = y or 0,
        -- altura da linha
        line_height = 12,
        -- line wrapping
        wrap = true,
        -- Várias instâncias de DecoratedText
        text = {}
    }

    instanceof(instance, Textarea)

    return instance
end

function Textarea:line_spacing()
    return (self.line_height-CHAR_H)/2
end

function Textarea:delete(n)
    while n > 0 do
        local deleted = self:try_delete(n)
        n -= deleted
        self.cursor -= deleted

        if deleted == 0 then break end
    end

    if #self.text > 0 then
        local last = self.text[#self.text]

        self.cursor_x = last.x+measure(last.text)
        self.cursor_y = last.y
    else
        self.cursor_x = self.x
        self.cursor_y = self.y
    end
end

function Textarea:try_delete(n)
    if #self.text > 0 then
        local deleted = 0
        local from = self.text[#self.text]

        if n < #from.text then
            from.text = from.text:sub(0, #from.text-n)

            return n
        else
            remove(self.text, #self.text)
            return #from.text
        end
    else
        return 0
    end
end

function Textarea:newline()
    self.cursor_x = self.x
    self.cursor_y += self.line_height

    if self.cursor_y >= self.y+self.h then
        self:scroll(-self.line_height)
    end
end

function Textarea:scroll(delta)
    for _, text in ipairs(self.text) do
        text.y += delta
    end

    self.cursor_y += delta
end

function Textarea:add(text)
    text.x, text.y = self.cursor_x, self.cursor_y
    text.align = 0

    local texts = self:advance_cursor(text)

    for _, text in ipairs(texts) do
        insert(self.text, text)
    end

    if self.cursor_y >= self.y+self.h then
        self:scroll(-self.line_height)
    end

    return self
end

function Textarea:draw()
    for _, text in ipairs(self.text) do
        if text.y+self.line_height > self.y and text.y < self.y+self.h then
            text:draw()
        end
    end
end

function Textarea:advance_cursor(text)
    local by = text.text
    local texts = {}

    self.cursor += #by

    self.cursor_x += measure(by)
    
    if self.cursor_x > self.x+self.w and self.wrap then
        local overflow = math.ceil((self.cursor_x-(self.x+self.w))/CHAR_W)

        self.cursor_x = self.x
        self.cursor_y += self.line_height

        local before, after = text:sub(0, #by-overflow), text:sub(#by-overflow+1, #by)

        after.x = self.cursor_x
        after.y = self.cursor_y

        insert(texts, before)

        local nested_texts = self:advance_cursor(after)

        for _, text in ipairs(nested_texts) do
            insert(texts, text)
        end
    else
        insert(texts, text)
    end

    return texts
end

return Textarea
