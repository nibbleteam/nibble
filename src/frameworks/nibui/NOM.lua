local iv = require('nibui.InterpolatedValue')
local Widget = require('nibui.Widget')
local DynamicValue = require('nibui.DynamicValue')

local DEFAULT_W = 320
local DEFAULT_H = 240

local NOM = {}

-- DynamicValues predefinidos
NOM.helpers = {
    ['=>'] = function (path, props)
        local nom = copy(require(path))

        if props then
            for k, v in pairs(props) do
                if type(k) == 'number' then
                    table.insert(nom, v)
                else
                    nom[k] = v
                end
            end
        end

        return nom
    end,
    ['%'] = function (value, prop)
        return DynamicValue:new('dynamic', function (widget)
            return widget.parent[prop]*value/100
        end)
    end,
    ['^'] = function (prop)
        return DynamicValue:new('dynamic', function (widget)
            return widget.parent[prop]
        end)
    end,
    ['.'] = function (prop)
        return DynamicValue:new('dynamic', function (widget)
            return widget[prop]
        end)
    end,
    ['fn'] = function (fn)
        return DynamicValue:new('dynamic', fn)
    end,
    ['+'] = function (a, b)
        return DynamicValue:new('dynamic', function(w)
            if type(a) == 'table' and a.isdynamicvalue then
                a = a:get(w)
            end

            if type(b) == 'table' and b.isdynamicvalue then
                b = b:get(w)
            end

            return a+b
        end)
    end,
    ['-'] = function (a, b)
        return DynamicValue:new('dynamic', function(w)
            if type(a) == 'table' and a.isdynamicvalue then
                a = a:get(w)
            end

            if type(b) == 'table' and b.isdynamicvalue then
                b = b:get(w)
            end

            return a-b
        end)
    end,
    ['*'] = function (a, b)
        return DynamicValue:new('dynamic', function(w)
            if type(a) == 'table' and a.isdynamicvalue then
                a = a:get(w)
            end

            if type(b) == 'table' and b.isdynamicvalue then
                b = b:get(w)
            end

            return a*b
        end)
    end,
    ['/'] = function (a, b)
        return DynamicValue:new('dynamic', function(w)
            if type(a) == 'table' and a.isdynamicvalue then
                a = a:get(w)
            end

            if type(b) == 'table' and b.isdynamicvalue then
                b = b:get(w)
            end

            return a/b
        end)
    end,
}

function NOM.dynamic (k)
    return NOM.helpers[k]
end

NOM.helpers['top'] = NOM.dynamic '^' 'y'
NOM.helpers['left'] = NOM.dynamic '^' 'x'
NOM.helpers['right'] = NOM.dynamic '+' (NOM.dynamic 'left', NOM.dynamic '^' 'w')
NOM.helpers['bottom'] = NOM.dynamic '+' (NOM.dynamic 'top', NOM.dynamic '^' 'h')

-- static: Makes a document from a description
function NOM:make_document(desc, parent)
    local widget_desc = desc
    local widget = Widget:new(widget_desc, self, parent)

    for k, v in pairs(desc) do
        -- Only iterate over unamed properties 
        -- we don't use ipairs to avoid stopping
        -- at nil
        if type(k) == "number" then
            local child = self:make_document(v, widget)

            -- Relationships
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

    instanceof(instance, NOM)

    instance.root = instance:make_document(desc, {
        x = 0, y = 0,
        w = DEFAULT_W, h = DEFAULT_H,
    })

    return instance
end

function NOM:use(feature)
    self.features[feature] = true

    return self
end

function NOM:draw()
    self.root:draw()
    clip(0, 0, 320, 240)

    if self.features.cursor then
        self:draw_cursor()
    end
end

function NOM:init()
    self:update(0)
    self.root:init()
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
    local x, y = read16(MOUSE), read16(MOUSE+2)
    local drag = false
    self.mouse.click = read8(MOUSE+4)

    if self.mouse.click == 1 then
        self:click({ x = x, y = y }, true)
    end

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

function NOM:click(event, press)
    self.root:click(event, press)
end

function NOM:move(event)
    self.root:move(event)
end

return NOM
