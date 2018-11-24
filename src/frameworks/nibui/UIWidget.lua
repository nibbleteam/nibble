local UIWidget = {}

function UIWidget:new(config)
    local instance = {
        id = config.id or '',
        border_color = config.border_color or 0,
        background = config.background or 0,
        shadow_color = config.shadow_color or 0,
        x = config.x or 0, y = config.y or 0,
        w = config.w or 0, h = config.h or 0,
        z = config.z or 0, radius = config.radius or 0,
        onclick = config.onclick,
        onenter = config.onenter, onleave = config.onleave,
        content = config.content or '',
        mouse = {
            inside = false
        },
        children = {}, parent = nil
    }

    lang.instanceof(instance, UIWidget)

    return instance
end

function UIWidget:get(value)
    if type(value) == 'function' then
        return value(self)
    else
        return value
    end
end

function UIWidget:draw()
    local x, y = self:get(self.x), self:get(self.y)
    local w, h = self:get(self.w), self:get(self.h)
    local r = self:get(self.radius)
    local content = self:get(self.content)
    local background = self:get(self.background)
    local shadow_color = self:get(self.shadow_color)
    local border_color = self:get(self.border_color)
    local z = self:get(self.z)

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
    -- TODO: aligned text
    print(content, x+w/2-#content/2*8, y+h/2-4)

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
        if self.mouse.inside then
            self:leave(event)
        end
    end
end

function UIWidget:leave(event)
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

function UIWidget:in_bounds(e)
    return e.x >= self:get(self.x) and e.y >= self:get(self.y) and
           e.x < self:get(self.x)+self:get(self.w) and
           e.y < self:get(self.y)+self:get(self.h)
end

return UIWidget
