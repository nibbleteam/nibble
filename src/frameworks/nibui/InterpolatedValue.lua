local Easing = require('nibui.Easing')

local InterpolatedValue = {}

function InterpolatedValue:new(v)
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

    lang.instanceof(instance, InterpolatedValue)

    return instance
end

function InterpolatedValue:get(v)
    if type(v) == 'function' then
        return v()
    elseif type(v) == 'table' and v.value then
        return v.value
    end

    return v
end

function InterpolatedValue:set(v, time, easing)
    -- Default time and interpolation
    time = time or 1
    easing = easing or Easing.Linear

    -- From
    self.interpolation.from.v = self.value
    self.interpolation.from.t = clock()

    -- To
    self.interpolation.to.v = v
    self.interpolation.to.t = clock()+time

    -- Using easing
    self.interpolation.easing = easing
end

function InterpolatedValue:update(dt)
    -- Elapsed time
    local et = clock() - self.interpolation.from.t
    -- Total time
    local t = self.interpolation.to.t-self.interpolation.from.t
    -- Interpolated value (0-1)
    local i = self.interpolation.easing(et/t)

    -- Initial value
    local iv = self:get(self.interpolation.from.v)

    -- Interpolation delta
    local dv = self:get(self.interpolation.to.v)-iv

    -- Set interpolated value
    self.value = iv+dv*i
end

return InterpolatedValue
