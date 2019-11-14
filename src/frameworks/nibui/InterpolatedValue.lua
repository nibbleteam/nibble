local Easing = require('nibui.Easing')

local InterpolatedValue = {}

function InterpolatedValue:new(v, w)
    local instance = {
        -- Valor inicial e final + função de interpolação
        interpolation = {
            to = {
                v = v, t = 0
            },
            from = {
                v = v, t = 0
            },
            easing = Easing.Linear,
        },
        dirty = 0,
    }
    
    local mt = {
        __index = function (self, idx)
            if idx == 'value' then
                if type(self.interpolation.from.v) == 'number' then
                    -- Elapsed time
                    local et = clock() - self.interpolation.from.t
                    -- Total time
                    local t = self.interpolation.to.t-self.interpolation.from.t
                    -- Position
                    local p = et/t

                    if t == 0 then
                        return self:get(self.interpolation.to.v, w)
                    end

                    if p ~= p then
                        p = 0
                    end

                    -- Interpolated value (0-1)
                    local i = self.interpolation.easing(p)

                    -- Initial value
                    local iv = self:get(self.interpolation.from.v, w)

                    -- Interpolation delta
                    local dv = self:get(self.interpolation.to.v, w)-iv

                    -- Set interpolated value
                    return iv+dv*i
                else
                    return self:get(self.interpolation.from.v, w)
                end
            else
                return rawget(self, idx) or rawget(InterpolatedValue, idx)
            end
        end
    }

    setmetatable(instance, mt)

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
    self.interpolation.from.t = clock()

    -- To
    self.interpolation.to.v = v
    self.interpolation.to.t = clock()+time

    -- Using easing
    self.interpolation.easing = easing

    self.dirty = time
end

function InterpolatedValue:update(dt, w)
    local dirty = self.dirty

    self.dirty -= dt

    return dirty >= 0
end

return InterpolatedValue
