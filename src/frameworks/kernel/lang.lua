local lang = {}

function lang.new(kind, obj)
    local hierarchy = {}

    repeat
        local mt = getmetatable(kind)

        table.insert(hierarchy, lang.copy(kind))
        kind = mt and mt.__index
    until kind == nil

    for n, kind in ipairs(hierarchy) do
        if n+1 < #hierarchy then
            lang.instanceof(kind, hierarchy[n+1])
        end
    end

    print("Called new with a hierarchy of "..tostring(#hierarchy).." levels")

    return lang.instanceof(obj, hierarchy[1])
end

function lang.concat(t, ...) -- source: https://stackoverflow.com/questions/34921025/concatenate-table-sequences-in-lua
    local new = {unpack(t)}

    for i,v in ipairs({...}) do
        for ii,vv in ipairs(v) do
            new[#new+1] = vv
        end
    end

    return new
end

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
