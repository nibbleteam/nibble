local DynamicValue = require('nibui.DynamicValue')

local Widget = {}

function Widget:new(config, document, parent)
    local defaults = {
        -- Colors
        shadow_color = 0, border_color = 0, background = 0, color = 15,
        cmap = {
            {15, 15},
            {7, 7},
        },
        -- Position and size
        border_size = 0,
        x = 0, y = 0, z = 0, w = 0, h = 0, radius = 0,
        -- Content
        content = '', text_align = 'center', vertical_align = 'middle',
        text_palette = 0,
        palette = 0,
        -- Padding
        padding_top = 0, padding_left = 0, padding_bottom = 0, padding_right = 0,
    }

    local instance = {
        props = {},
        -- Mouse
        mouse = { inside = false },
        -- Tree
        children = {}, parent = nil, document = document, parent = parent,
        -- Methods
        onpress = function() end,
        onclick = function() end,
        onenter = function() end,
        onleave = function() end,
        onmove = function() end,
        -- Redraw
        dirty = true,
    }

    for k, _ in zip(config, defaults) do
        if config[k] then
            if type(config[k]) == 'number' then
                instance.props[k] = DynamicValue:new('interpolated', config[k], instance)
            elseif type(config[k]) == 'function' then
                instance[k] = config[k]
            elseif type(config[k]) == 'table' and config[k].isdynamicvalue then
                instance.props[k] = DynamicValue:new('interpolated', config[k], instance)
            else
                instance.props[k] = DynamicValue:new('static', config[k])
            end
        else
            if type(defaults[k]) == 'number' then
                instance.props[k] = DynamicValue:new('interpolated', defaults[k], instance)
            else
                instance.props[k] = DynamicValue:new('static', defaults[k])
            end
        end
    end

    setmetatable(instance, Widget)

    if config.ref then
        config.ref(instance)
    end

    return instance
end

-- Acesso

-- Leitura
function Widget:__index(k)
    if self.props[k] then
        return self.props[k]:get(self)
    else
        local raw = rawget(self, k)

        if raw then
            return raw
        else
            return Widget[k]
        end
    end
end

-- Escrita
function Widget:__newindex(k, v)
    if self.props[k] then
        self.props[k]:set(v, self)
    else
        if type(v) == 'number' then
            self.props[k] = DynamicValue:new('interpolated', v, self)
        elseif type(v) == 'function' then
            rawset(self, k, v)
        elseif type(v) == 'table' and v.isdynamicvalue then
            self.props[k] = v
        else
            self.props[k] = DynamicValue:new('static', v)
        end
    end

    self:set_dirty()
end

function Widget:update(dt)
    -- Atualiza interpolated values
    for name, prop in pairs(self.props) do
        if prop.kind == 'interpolated' then
            if prop:update(dt, self) then
                if self.parent.set_dirty then
                    self.parent:set_dirty()
                else
                    self:set_dirty()
                end
            end
        end
    end

    -- Atualiza filhos
    for _, child in ipairs(self.children) do
        child:update(dt)
    end

    if self.onupdate then
        self:onupdate()
    end
end

function Widget:draw_3slice(x, y, w, h, sx, sy, sw, sh, sl1, sl2)
    -- Right side

    w = math.ceil(w)

    clip(x, y, w, h)

    custom_sprite(x, y, sx, sy, sl1, sh, self.palette)

    -- Middle

    local step = sl2-sl1

    -- Setup a clip rect for the middle
    clip(x+sl1, y, w-(sw-step), h)

    -- Draw the middle
    for dx=0,w,step do
        custom_sprite(x+sl1+dx, y, sx+sl1, sy, step, sh, self.palette)
    end

    -- Restore clipping
    clip(x, y, w, h)

    -- Left side

    custom_sprite(x+w-sw+sl2, y, sx+sl2, sy, sw-sl2, sh, self.palette)
end

function Widget:draw_9slice(x, y, w, h, sx, sy, sw, sh, sl1, sl2, sl3, sl4)
    -- Top
    self:draw_3slice(x, y, w, sl3, sx, sy, sw, sl3, sl1, sl2)

    h = math.ceil(h)

    -- Middle
    local step_h = sl4-sl3
    local dy = sl3

    for dy=sl3,h-(sh-sl4),step_h do
        --local height = math.max(math.min(step_h, h-(sh-sl4)-sl3), 0)
        local height = math.min(step_h, h-(sh-sl4)-dy)

        self:draw_3slice(x, y+dy, w, height, sx, sy+sl3, sw, step_h, sl1, sl2)
    end

    -- Bottom
    self:draw_3slice(x, y+h-sh+sl4, w, sh-sl4, sx, sy+sl4, sw, sh-sl4, sl1, sl2)

    clip(self.x, self.y, self.w, self.h)
end

-- Loop

function Widget:draw()
    if self.dirty then
        self.dirty = false

        local x, y = self.x, self.y
        local w, h = self.w, self.h
        local r = math.floor(self.radius)
        local content = self.content
        local shadow_color = math.floor(self.shadow_color)
        local border_color = math.floor(self.border_color)
        local border_size = math.floor(self.border_size)
        local z = math.floor(self.z)

        clip(x, y, w, h)

        if z ~= 0 then
          fill_rect(x+r, y+z, w-r*2, h, shadow_color)
          fill_rect(x, y+r+z, w, h-r*2, shadow_color)

          if r ~= 0 then
            fill_circ(x+r, y+r+z, r, shadow_color)
            fill_circ(x+w-r-1, y+r+z, r, shadow_color)
            fill_circ(x+r, y+h-r+z-1, r, shadow_color)
            fill_circ(x+w-r-1, y+h-r+z-1, r, shadow_color)
          end
        end

        fill_rect(x+r, y, w-r*2, h, border_color)
        fill_rect(x, y+r, w, h-r*2, border_color)

        if r ~= 0 then
            fill_circ(x+r, y+r, r, border_color)
            fill_circ(x+w-r-1, y+r, r, border_color)
            fill_circ(x+r, y+h-r-1, r, border_color)
            fill_circ(x+w-r-1, y+h-r-1, r, border_color)
        end

        if type(self.background) ~= 'table' then
            local background = math.floor(self.background)

            do
                local w = w-border_size*2
                local h = h-border_size*2
                local x = x+border_size
                local y = y+border_size
                local r = math.max(r-border_size, 0)

                fill_rect(x+r, y, w-r*2, h, background)
                fill_rect(x, y+r, w, h-r*2, background)

                if r ~= 0 then
                    fill_circ(x+r, y+r, r, background)
                    fill_circ(x+w-r-1, y+r, r, background)
                    fill_circ(x+r, y+h-r-1, r, background)
                    fill_circ(x+w-r-1, y+h-r-1, r, background)
                end
            end
        else
            if #self.background == 2 then
                local sprite_x, sprite_y = self.background[1], self.background[2]

                sprite(x, y, sprite_x, sprite_y, self.palette)
            elseif #self.background == 4 then
                local sprite_x, sprite_y, sprite_w, sprite_h = unwrap(self.background)

                custom_sprite(x, y, sprite_x, sprite_y, sprite_w, sprite_h, self.palette)
            elseif #self.background == 6 then
                self:draw_3slice(x, y, w, h, unwrap(self.background))
            elseif #self.background == 8 then
                self:draw_9slice(x, y, w, h, unwrap(self.background))
            end
        end


        local tx, ty = 0, 0

        if self.text_align == 'left' then
            tx = self.padding_left
        elseif self.text_align == 'center' then
            tx = x+w/2-measure(content)/2
        elseif self.text_align == 'right' then
            tx = w-measure(content)-self.padding_right
        end

        if self.vertical_align == 'top' then
            ty = 0
        elseif self.vertical_align == 'middle' then
            ty = y+h/2-4
        elseif self.vertical_align == 'bottom' then
            ty = h-8
        end

        -- TODO: use decorated text
        for i, v in ipairs(self.cmap) do
            swap_colors(math.floor(v[1]), math.floor(v[2]))
        end

        print(content, tx, ty+self.padding_top-self.padding_bottom, self.text_palette)

        for i, v in ipairs(self.cmap) do
            swap_colors(math.floor(v[1]), math.floor(v[1]))
        end
    end

    for _, child in ipairs(self.children) do
        child:draw()
    end
end

-- Eventos

function Widget:click(event, press)
    if self:in_bounds(event) then
        for i=#self.children,1,-1 do
            local child = self.children[i]

            local consumed = child:click(event, press)

            if consumed then
                if consumed == 1 then
                    return 1
                else
                    break
                end
            end
        end

        if press then
            if self.onpress then
                if self:onpress(event) then
                    return 1
                end
            end
        else
            if self.onclick then
                if self:onclick(event) then
                    return 1
                end
            end
        end

        return 0
    end
end

function Widget:move(event, offset, left)
    if self:mouse_sprite_in_bounds(event, offset) then
        self.mouse.sprite_inside = true

        self:set_dirty()
    elseif self.mouse.sprite_inside then
        self.mouse.sprite_inside = false

        self:set_dirty()
    end

    if self:in_bounds(event) and not left then
        if not self.mouse.inside then
            self.mouse.inside = true

            if self.onenter then
                if self:onenter(event) then
                    return true
                end
            end

            local c = self.document.cursor[self.document.cursor.state]

            mouse_cursor(c.x, c.y, c.w, c.h)
        end

        if self.onmove then
            if self:onmove(event) then
                return true
            end
        end

        local left = false

        for i=#self.children,1,-1 do
            local child = self.children[i]

            left = child:move(event, offset, left) or left
        end

        return true
    else
        self:leave(event)
    end
end

function Widget:leave(event)
    if self.mouse.inside then
        self:set_dirty()

        self.mouse.inside = false

        if self.onleave then
            self:onleave(event)
        end

        for _, child in ipairs(self.children) do
            child:leave(event)
        end
    end
end

function Widget:init()
    for _, child in ipairs(self.children) do
        child:init()
    end
end

function Widget:in_point(x, y)
    return x >= self.x and y >= self.y and
           x < self.x+self.w and
           y < self.y+self.h
end

function Widget:mouse_sprite_in_bounds(e, offset)
    e = copy(e)

    e.x += offset.x
    e.y += offset.y

    return self:in_point(e.x, e.y) or
           self:in_point(e.x+8, e.y) or
           self:in_point(e.x+8, e.y+8) or
           self:in_point(e.x, e.y+8)
end

function Widget:in_bounds(e)
    return self:in_point(e.x, e.y)
end

function Widget.inside_rect(e, x, y, w, h)
    return e.x >= x and e.y >= y and
           e.x < x+w and
           e.y < y+h
end

function Widget:set_dirty()
    self.dirty = true

    for _, child in ipairs(self.children) do
        child:set_dirty()
    end
end

function Widget:find(id)
    if self.id == id then
        return self
    end

    for _, child in ipairs(self.children) do
        local found = child:find(id)

        if found then
            return found
        end
    end

    return nil
end

return Widget
