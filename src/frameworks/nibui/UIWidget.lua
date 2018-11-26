local iv = require('nibui.InterpolatedValue')
local UIWidget = {}

function UIWidget.bind(self, fn)
    return function()
        return fn(self)
    end
end

function UIWidget:new(config, document)
    local defaults = {
        -- Colors
        shadow_color = 0, border_color = 0, background = 0, color = 15,
        -- Position and size
        x = 0, y = 0, z = 0, w = 0, h = 0, radius = 0,
        -- Content
        content = '', text_align = 'center', vertical_align = 'middle',
        -- Methods
        onclick = nil, onenter = nil, onleave = nil,
        -- Padding
        padding = { top = 0, left = 0, bottom = 0, right = 0 },
        -- Mouse
        mouse = { inside = false },
        -- Tree
        children = {}, parent = nil, document = document
    }

    local instance = {}

    for k, _ in lang.zip(defaults, config) do
        if config[k] then
            if type(config[k]) == 'number' then
                instance[k] = iv:new(config[k])
            elseif type(config[k]) == 'function' and (not UIWidget[k]) and (k:sub(1, 1) ~= '_') then
                instance[k] = iv:new(UIWidget.bind(instance, config[k]))
            else
                instance[k] = config[k]
            end
        else
            if type(defaults[k]) == 'number' then
                instance[k] = iv:new(defaults[k])
            else
                instance[k] = defaults[k]
            end
        end
    end

    lang.instanceof(instance, UIWidget)

    return instance
end

function UIWidget:onenter()
end

function UIWidget:onclick()
end

function UIWidget:onleave()
end

function UIWidget:onmove()
end

function UIWidget:get(value)
    if type(value) == 'function' then
        return value(self)
    elseif type(value) == 'table' and value.value then
        return self:get(value.value)
    else
        return value
    end
end

function UIWidget:update(dt)
    if self.children then
        for _, child in ipairs(self.children) do
            child:update(dt)
        end
    end

    for _, v in pairs(self) do
        if type(v) == 'table' and v.update and v.value then
            v:update(dt, self)
        end
    end
end

function UIWidget:draw()
    local x, y = self:get(self.x), self:get(self.y)
    local w, h = self:get(self.w), self:get(self.h)
    local r = math.floor(self:get(self.radius))
    local content = self:get(self.content)
    local background = math.floor(self:get(self.background))
    local shadow_color = math.floor(self:get(self.shadow_color))
    local border_color = math.floor(self:get(self.border_color))
    local z = math.floor(self:get(self.z))

    -- TODO: Optimize common cases

    rectf(x+r, y+z, w-r*2, h, shadow_color)
    rectf(x, y+r+z, w, h-r*2, shadow_color)

    circf(x+r, y+r+z, r, shadow_color)
    circf(x+w-r, y+r+z, r, shadow_color)
    circf(x+r, y+h-r+z, r, shadow_color)
    circf(x+w-r, y+h-r+z, r, shadow_color)

    rect(x+r, y-1, w-r*2+1, h+1, border_color)
    rect(x, y+r-1, w+1, h-r*2+1, border_color)

    circf(x+r, y+r, r+1, border_color)
    circf(x+w-r, y+r, r+1, border_color)
    circf(x+r, y+h-r, r+1, border_color)
    circf(x+w-r, y+h-r, r+1, border_color)

    rectf(x+r, y, w-r*2, h, background)
    rectf(x, y+r, w, h-r*2, background)

    circf(x+r, y+r, r, background)
    circf(x+w-r, y+r, r, background)
    circf(x+r, y+h-r, r, background)
    circf(x+w-r, y+h-r, r, background)

    -- TODO: use decorated text
    col(15, math.floor(self:get(self.color)))

    local tx, ty = 0, 0

    if self.text_align == 'left' then
        tx = self.padding.left
    elseif self.text_align == 'center' then
        tx = x+w/2-#content/2*8
    elseif self.text_align == 'right' then
        tx = w-#content*8-self.padding.right
    end

    if self.vertical_align == 'top' then
        ty = self.padding.top
    elseif self.vertical_align == 'middle' then
        ty = y+h/2-4
    elseif self.vertical_align == 'bottom' then
        ty = h-8-self.padding.bottom
    end
    
    print(content, tx, ty)

    col(15, 15)

    if self.children then
        for _, child in ipairs(self.children) do
            child:draw()
        end
    end
end

function UIWidget:click(event)
    if self:in_bounds(event) then
        if self.children then
            for _, child in ipairs(self.children) do
                if child:click(event) then
                    return true
                end
            end
        end

        if self.onclick then
            if self:onclick(event) then
                return true
            end
        end

        return true
    end
end

function UIWidget:move(event)
    if self:in_bounds(event) then
        if not self.mouse.inside then
            self.mouse.inside = true

            if self.onenter then
                if self:onenter(event) then
                    return
                end
            end
        end

        if self.onmove then
            if self:onmove(event) then
                return
            end
        end

        if self.children then
            for _, child in ipairs(self.children) do
                child:move(event)
            end
        end
    else
        self:leave(event)
    end
end

function UIWidget:leave(event)
    if self.mouse.inside then
        self.mouse.inside = false

        if self.onleave then
            self:onleave(event)
        end

        if self.children then
            for _, child in ipairs(self.children) do
                child:leave(event)
            end
        end
    end
end

function UIWidget:in_bounds(e)
    return e.x >= self:get(self.x) and e.y >= self:get(self.y) and
           e.x < self:get(self.x)+self:get(self.w) and
           e.y < self:get(self.y)+self:get(self.h)
end

return UIWidget
