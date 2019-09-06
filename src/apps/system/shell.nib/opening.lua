local length = 0.5
local stripes = 5
local color = 16

local stripe = 0

function opening(start, t)
    local p = (t-start)/length

    if p > 1 then
        p = 1
    end

    for i=1,stripes do
        rectf(320/stripes*(i-1), 0,
              320/stripes,
              240*i*p,
              color)
    end
end
