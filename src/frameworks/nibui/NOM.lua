local UIWidget = require('nibui/UIWidget')

local DEFAULT_W = 320
local DEFAULT_H = 240

local NOM = {}

function percent(prop, prop2, value)
    if not value then
        value = prop2

        return function (widget)
            return widget.parent:get(widget.parent[prop])*value/100
        end
    else
        return function (widget)
            return widget.parent:get(widget.parent[prop])+
                   widget.parent:get(widget.parent[prop2])*value/100
        end
    end
end

function parent(prop)
    return function (widget)
        return widget.parent:get(widget.parent[prop])
    end
end

function top()
    return parent('y')
end

function left()
    return parent('x')
end

function bottom()
    return percent('y', 'h', 100)
end

function right()
    return percent('x', 'w', 100)
end

function calc(fn, value)
    return function(w)
        return fn(w)+value
    end
end

-- static: Makes a document from a description
function NOM.make_document(desc)
    local widget_desc = desc
    local widget = UIWidget:new(widget_desc)

    for k, v in pairs(desc) do
        -- Only iterate over unamed properties 
        -- we don't use ipairs to avoid stopping
        -- at nil
        if type(k) == "number" then
            local child = NOM.make_document(v)

            -- Relationships
            child.parent = widget
            table.insert(widget.children, child)
        end
    end

    return widget
end

function NOM:new(desc)
    local instance = {
        root = NOM.make_document(desc),
        features = {},
        cursor = {
            offset = { x = -3, y = -1 },
            normal = {
                x = 56, y = 80,
                w = 8, h = 8
            },
            pressing = {
                x = 64, y = 80,
                w = 8, h = 8
            },
            state = 'normal'
        },
        mouse = { x = 0, y = 0 }
    }

    instance.root.parent = {
        x = 0, y = 0,
        w = DEFAULT_W, h = DEFAULT_H,
        get = UIWidget.get
    }

    lang.instanceof(instance, NOM)

    return instance
end

function NOM:use(feature)
    self.features[feature] = true

    return self
end

function NOM:draw()
    self.root:draw()

    if self.features.cursor then
        self:draw_cursor()
    end
end

function NOM:update()
    self:update_mouse()
end

function NOM:draw_cursor()
    local c = self.cursor[self.cursor.state]

    pspr(self.mouse.x+self.cursor.offset.x, self.mouse.y+self.cursor.offset.y,
         c.x, c.y, c.w, c.h)
end

function NOM:update_mouse()
    local x, y = read16(154442), read16(154444)
    self.mouse.click = read8(154446)

    if self.mouse.click == 2 then
        self.cursor.state = 'pressing'
    else
        self.cursor.state = 'normal'
    end

    if self.mouse.click == 3 then
        self:click({ x = x, y = y })
    end

    if self.mouse.x ~= x or self.mouse.y ~= y then
        self:move({ x = x, y = y })
        self.mouse.x, self.mouse.y = x, y
    end
end

function NOM:click(event)
    self.root:click(event)
end

function NOM:move(event)
    self.root:move(event)
end

return NOM
