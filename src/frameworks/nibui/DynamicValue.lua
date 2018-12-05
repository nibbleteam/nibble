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

    instanceof(instance, DynamicValue)

    return instance
end

function DynamicValue:set(value)
    if self.kind == 'static' or self.kind == 'dynamic' then
        -- Caso 1: transfere conteúdo
        self.kind, self.value = value.kind, value.value
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
        return self.value.value
    end
end

function DynamicValue:update(dt, w)
    self.value:update(dt, w)
end

return DynamicValue
