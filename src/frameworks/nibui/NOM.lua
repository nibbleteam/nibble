local iv = require('nibui.InterpolatedValue')
local UIWidget = require('nibui/UIWidget')

local DEFAULT_W = 320
local DEFAULT_H = 240

local NOM = {}

function extend(path, props)
    local nom = lang.copy(require(path))

    for k, v in pairs(props) do
        if type(k) == 'number' then
            table.insert(nom, v)
        else
            nom[k] = v
        end
    end

    return nom
end

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

function this(prop)
    return function (widget)
        return widget:get(widget[prop])
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
function NOM:make_document(desc)
    local widget_desc = desc
    local widget = UIWidget:new(widget_desc, self)

    for k, v in pairs(desc) do
        -- Only iterate over unamed properties 
        -- we don't use ipairs to avoid stopping
        -- at nil
        if type(k) == "number" then
            local child = self:make_document(v)

            -- Relationships
            child.parent = widget
            table.insert(widget.children, child)
        end
    end

    return widget
end

function NOM:new(desc)
    local instance = {
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

    lang.instanceof(instance, NOM)

    instance.root = instance:make_document(desc)

    instance.root.parent = {
        x = 0, y = 0,
        w = DEFAULT_W, h = DEFAULT_H,
        get = UIWidget.get
    }


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

function NOM:update(dt)
    self.root:update(dt)

    self:update_mouse()
end

function NOM:find(selector, node)
    if selector:sub(1, 1) == '#' then
        local id = selector:sub(2, -1)

        if node then
            if node.id == id then
                return node
            end

            for _, c in ipairs(node.children) do
                local r = self:find(selector, c)

                if r then
                    return r
                end
            end

            return nil
        else
            local found = self:find(selector, self.root)

            if not found then
                dprint('nom:', 'could not find', selector, id)
            else
                return found
            end
        end
    end

    return nil
end

function NOM:draw_cursor()
    local c = self.cursor[self.cursor.state]

    pspr(self.mouse.x+self.cursor.offset.x, self.mouse.y+self.cursor.offset.y,
         c.x, c.y, c.w, c.h)
end

function NOM:update_mouse()
    local x, y = read16(154442), read16(154444)
    local drag = false
    self.mouse.click = read8(154446)

    if self.mouse.click == 2 then
        self.cursor.state = 'pressing'
        drag = true
    else
        self.cursor.state = 'normal'
    end

    if self.mouse.click == 3 then
        self:click({ x = x, y = y })
    end

    if self.mouse.x ~= x or self.mouse.y ~= y then
        self:move({ x = x, y = y, drag = drag })
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
