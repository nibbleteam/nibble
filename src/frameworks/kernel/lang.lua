local lang = {}

function lang.instanceof(a, b)
    setmetatable(a, {__index=b})
    return a
end

function lang.copy(orig) -- source:  http://lua-users.org/wiki/CopyTable
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[lang.copy(orig_key)] = lang.copy(orig_value)
        end
        setmetatable(copy, lang.copy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function lang.zip(t, ...) -- source: https://stackoverflow.com/questions/33849777/one-loop-for-iterating-through-multiple-lua-tables
  local i, a, k, v = 1, {...}
  return
    function()
      repeat
        k, v = next(t, k)
        if k == nil then
          i, t = i + 1, a[i]
        end
      until k ~= nil or not t
      return k, v
    end
end

return lang
