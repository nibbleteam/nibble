local Easing = require('nibui.Easing')

local InterpolatedValue = {}

function InterpolatedValue:new(v, w)
    local instance = {
        value = v,

        -- Valor inicial e final + função de interpolação
        interpolation = {
            to = {
                v = v, t = 0
            },
            from = {
                v = v, t = 0
            },
            easing = Easing.Linear
        }
    }

    instanceof(instance, InterpolatedValue)

    instance.value = instance:get(instance.value, w)

    return instance
end

function InterpolatedValue:get(v, w)
    if type(v) == 'table' and v.isdynamicvalue then
        return v:get(w)
    end

    return v
end

function InterpolatedValue:set(v, time, easing)
    if type(v) == 'table' and not v.isdynamicvalue then
        time = v[2]
        easing = v[3]
        v = v[1]
    end

    -- Default time and interpolation
    time = time or 0
    easing = easing or Easing.Linear

    -- From
    self.interpolation.from.v = self.value
    self.interpolation.from.t = clock()*10

    -- To
    self.interpolation.to.v = v
    self.interpolation.to.t = clock()*10+time

    -- Using easing
    self.interpolation.easing = easing
end

function InterpolatedValue:update(dt, w)
    -- Elapsed time
    local et = clock()*10 - self.interpolation.from.t
    -- Total time
    local t = self.interpolation.to.t-self.interpolation.from.t
    -- Position
    local p = et/t

    if p ~= p then
        p = 0
    end

    -- Interpolated value (0-1)
    local i = self.interpolation.easing(p)

    -- Initial value
    local iv = self:get(self.interpolation.from.v, w)

    -- Interpolation delta
    local dv = self:get(self.interpolation.to.v, w)-iv

    -- For change test
    local prev = self.value

    -- Set interpolated value
    self.value = iv+dv*i

    return self.value ~= prev
end

return InterpolatedValue
