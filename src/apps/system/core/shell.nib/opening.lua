local length = 0.4
local stripes = 8
local color = 1

function opening(start, t)
    local p = (t-start)/length

    if p > 1 then
        p = 1
    end

    for i=1,stripes do
        rectf(320/stripes*(i-1), 0,
              320/stripes,
              240*(stripes-i+1)*p,
              1)
    end
end
