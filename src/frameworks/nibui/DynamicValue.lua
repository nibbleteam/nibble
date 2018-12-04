local iv = require('nibui.InterpolatedValue')

local DynamicValue = {}

function DynamicValue:new(kind, value)
    local instance = {
        isdynamicvalue = true,
        -- static ou dynamic ou interpolated
        kind = kind or 'static',
        value = value or 0,
        -- ligado à?
        bound = nil
    }

    if kind == 'interpolated' then
        instance.value = iv:new(value)
    end

    instanceof(instance, DynamicValue)

    return instance
end

function DynamicValue:bind(to)
    self.bound = to

    return self
end

function DynamicValue:set(value, w)
    if w ~= nil then
        self.bound = w
    end

    if self.kind == 'static' or self.kind == 'dynamic' then
        -- Caso 1: transfere conteúdo
        self.kind, self.value = value.kind, value.value
    elseif self.kind == 'interpolated' then
        -- Caso 2: transfere  o valor atual
        if type(value) == 'table' and value.isdynamicvalue then
            self.value:set(value:get())
        else
            self.value:set(value)
        end
    end
end

function DynamicValue:get(w)
    if w ~= nil then
        self.bound = w
    end

    if self.kind == 'static' then
        return self.value
    elseif self.kind == 'dynamic' then
        return self.value(self.bound)
    elseif self.kind == 'interpolated' then
        return self.value.value:get()
    end
end

function DynamicValue:update(dt)
    self.value:update(dt)
end

return DynamicValue
