-- All functions here should take a x between 0, 1
-- and return a y between 0, 1

local Easing = {}

local function clamp(x)
    if x > 1 then
        return 1
    end

    if x < 0 then
        return 0
    end

    return x
end

function Easing.Linear(x)
    return clamp(x)
end

function Easing.InCubic(x)
    x = clamp(x)

    return x*x*x
end

function Easing.OutCubic(x)
    x = clamp(x)

    local xinv = 1-x

    return 1-xinv*xinv*xinv
end

function Easing.InOutCubic(x)
    x = clamp(x)
    
    local xinv = 1-x

    if x > 0.5 then
        return (1-xinv*xinv*xinv*2*2)
    else
        return x*x*x*2*2
    end
end

function Easing.OutElastic(x)
    x = clamp(x)

    return math.sin(-13 * math.pi*2 * (x + 1)) * math.pow(2, -10 * x) + 1
end

return Easing
