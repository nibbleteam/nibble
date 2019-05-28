local iv = require('nibui.InterpolatedValue')

local DynamicValue = {}

function DynamicValue:new(kind, value, w)
    local instance = {
        isdynamicvalue = true,
        -- static ou dynamic ou interpolated
        kind = kind or 'static',
        value = value or 0,
    }

    if kind == 'interpolated' then
        instance.value = iv:new(value, w)
    end

    local function get_value(value, w)
        if type(value) == 'table' and value.isdynamicvalue then
            return value:get(w)
        end

        return value
    end

    local meta = {
        __index = DynamicValue,
        __add = function(a, b)
            return DynamicValue:new('dynamic', function(w)
                local va, vb = get_value(a, w), get_value(b, w)

                return va+vb
            end)
        end,
        __sub = function(a, b)
            return DynamicValue:new('dynamic', function(w)
                local va, vb = get_value(a, w), get_value(b, w)

                return va-vb
            end)
        end,
        __mul = function(a, b)
            return DynamicValue:new('dynamic', function(w)
                local va, vb = get_value(a, w), get_value(b, w)

                return va*vb
            end)
        end,
        __div = function(a, b)
            return DynamicValue:new('dynamic', function(w)
                local va, vb = get_value(a, w), get_value(b, w)

                return va/vb
            end)
        end,
    }

    setmetatable(instance, meta)

    return instance
end

function DynamicValue:set(value)
    if self.kind == 'static' or self.kind == 'dynamic' then
        -- Caso 1: transfere conteúdo
        if type(value) == 'table' and value.isdynamicvalue then
            self.kind, self.value = value.kind, value.value
        else
            self.kind = 'static'
            self.value = value
        end
    elseif self.kind == 'interpolated' then
        -- Caso 2: transfere  o valor atual
        self.value:set(value)
    end
end

function DynamicValue:get(w)
    if self.kind == 'static' then
        return self.value
    elseif self.kind == 'dynamic' then
        return self.value(w)
    elseif self.kind == 'interpolated' then
        self.cache = self.cache or self.value.value

        return self.cache
    end
end

function DynamicValue:update(dt, w)
    self.cache = nil

    return self.value:update(dt, w)
end

return DynamicValue
