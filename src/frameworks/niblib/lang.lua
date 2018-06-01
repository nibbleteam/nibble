local lang = {}

function lang.instanceof(a, b)
    setmetatable(a, {__index=b})
end

return lang
