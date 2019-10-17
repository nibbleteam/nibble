package.preload[ "lulpeg" ] = assert( (loadstring or load)(
"-- LuLPeg, a pure Lua port of LPeg, Roberto Ierusalimschy's\
-- Parsing Expression Grammars library.\
-- \
-- Copyright (C) Pierre-Yves Gerardy.\
-- Released under the Romantic WTF Public License (cf. the LICENSE\
-- file or the end of this file, whichever is present).\
-- \
-- See http://www.inf.puc-rio.br/~roberto/lpeg/ for the original.\
-- \
-- The re.lua module and the test suite (tests/lpeg.*.*.tests.lua)\
-- are part of the original LPeg distribution.\
local _ENV,       loaded, packages, release, require_ \
    = _ENV or _G, {},     {},       true,    require\
\
local function require(...)\
    local lib = ...\
\
    -- is it a private file?\
    if loaded[lib] then \
        return loaded[lib]\
    elseif packages[lib] then \
        loaded[lib] = packages[lib](lib)\
        return loaded[lib]\
    else\
        return require_(lib)\
    end\
end\
\
--=============================================================================\
do local _ENV = _ENV\
packages['analizer'] = function (...)\
\
local u = require\"util\"\
local nop, weakkey = u.nop, u.weakkey\
local hasVcache, hasCmtcache , lengthcache\
    = weakkey{}, weakkey{},    weakkey{}\
return {\
    hasV = nop,\
    hasCmt = nop,\
    length = nop,\
    hasCapture = nop\
}\
\
end\
end\
--=============================================================================\
do local _ENV = _ENV\
packages['compiler'] = function (...)\
local assert, error, pairs, print, rawset, select, setmetatable, tostring, type\
    = assert, error, pairs, print, rawset, select, setmetatable, tostring, type\
local s, t, u = require\"string\", require\"table\", require\"util\"\
local _ENV = u.noglobals() ----------------------------------------------------\
local s_byte, s_sub, t_concat, t_insert, t_remove, t_unpack\
    = s.byte, s.sub, t.concat, t.insert, t.remove, u.unpack\
local   load,   map,   map_all, t_pack\
    = u.load, u.map, u.map_all, u.pack\
local expose = u.expose\
return function(Builder, LL)\
local evaluate, LL_ispattern =  LL.evaluate, LL.ispattern\
local charset = Builder.charset\
local compilers = {}\
local\
function compile(pt, ccache)\
    if not LL_ispattern(pt) then\
        error(\"pattern expected\")\
    end\
    local typ = pt.pkind\
    if typ == \"grammar\" then\
        ccache = {}\
    elseif typ == \"ref\" or typ == \"choice\" or typ == \"sequence\" then\
        if not ccache[pt] then\
            ccache[pt] = compilers[typ](pt, ccache)\
        end\
        return ccache[pt]\
    end\
    if not pt.compiled then\
        pt.compiled = compilers[pt.pkind](pt, ccache)\
    end\
    return pt.compiled\
end\
LL.compile = compile\
local\
function clear_captures(ary, ci)\
    for i = ci, #ary do ary[i] = nil end\
end\
local LL_compile, LL_evaluate, LL_P\
    = LL.compile, LL.evaluate, LL.P\
local function computeidex(i, len)\
    if i == 0 or i == 1 or i == nil then return 1\
    elseif type(i) ~= \"number\" then error\"number or nil expected for the stating index\"\
    elseif i > 0 then return i > len and len + 1 or i\
    else return len + i < 0 and 1 or len + i + 1\
    end\
end\
local function newcaps()\
    return {\
        kind = {}, \
        bounds = {},\
        openclose = {},\
        aux = -- [[DBG]] dbgcaps\
            {}\
    }\
end\
local\
function _match(dbg, pt, sbj, si, ...)\
        if dbg then -------------\
            print(\"@!!! Match !!!@\", pt)\
        end ---------------------\
    pt = LL_P(pt)\
    assert(type(sbj) == \"string\", \"string expected for the match subject\")\
    si = computeidex(si, #sbj)\
        if dbg then -------------\
            print((\"-\"):rep(30))\
            print(pt.pkind)\
            LL.pprint(pt)\
        end ---------------------\
    local matcher = compile(pt, {})\
    local caps = newcaps()\
    local matcher_state = {grammars = {}, args = {n = select('#',...),...}, tags = {}} \
    local  success, final_si, ci = matcher(sbj, si, caps, 1, matcher_state)\
        if dbg then -------------\
            print(\"!!! Done Matching !!! success: \", success, \
                \"final position\", final_si, \"final cap index\", ci,\
                \"#caps\", #caps.openclose)\
        end----------------------\
    if success then\
        clear_captures(caps.kind, ci)\
        clear_captures(caps.aux, ci)\
            if dbg then -------------\
            print(\"trimmed cap index = \", #caps + 1)\
            LL.cprint(caps, sbj, 1)\
            end ---------------------\
        local values, _, vi = LL_evaluate(caps, sbj, 1, 1)\
            if dbg then -------------\
                print(\"#values\", vi)\
                expose(values)\
            end ---------------------\
        if vi == 0\
        then return final_si\
        else return t_unpack(values, 1, vi) end\
    else\
        if dbg then print(\"Failed\") end\
        return nil\
    end\
end\
function LL.match(...)\
    return _match(false, ...) \
end\
function LL.dmatch(...)\
    return _match(true, ...) \
end\
for _, v in pairs{ \
    \"C\", \"Cf\", \"Cg\", \"Cs\", \"Ct\", \"Clb\",\
    \"div_string\", \"div_table\", \"div_number\", \"div_function\"\
} do\
    compilers[v] = load(([=[\
    local compile, expose, type, LL = ...\
    return function (pt, ccache)\
        local matcher, this_aux = compile(pt.pattern, ccache), pt.aux\
        return function (sbj, si, caps, ci, state)\
            local ref_ci = ci\
            local kind, bounds, openclose, aux \
                = caps.kind, caps.bounds, caps.openclose, caps.aux\
            kind      [ci] = \"XXXX\"\
            bounds    [ci] = si\
            openclose [ci] = 0\
            caps.aux       [ci] = (this_aux or false)\
            local success\
            success, si, ci\
                = matcher(sbj, si, caps, ci + 1, state)\
            if success then\
                if ci == ref_ci + 1 then\
                    caps.openclose[ref_ci] = si\
                else\
                    kind      [ci] = \"XXXX\"\
                    bounds    [ci] = si\
                    openclose [ci] = ref_ci - ci\
                    aux       [ci] = this_aux or false\
                    ci = ci + 1\
                end\
            else\
                ci = ci - 1\
            end\
            return success, si, ci\
        end\
    end]=]):gsub(\"XXXX\", v), v..\" compiler\")(compile, expose, type, LL)\
end\
compilers[\"Carg\"] = function (pt, ccache)\
    local n = pt.aux\
    return function (sbj, si, caps, ci, state)\
        if state.args.n < n then error(\"reference to absent argument #\"..n) end\
        caps.kind      [ci] = \"value\"\
        caps.bounds    [ci] = si\
        if state.args[n] == nil then\
            caps.openclose [ci] = 1/0\
            caps.aux       [ci] = 1/0\
        else\
            caps.openclose [ci] = si\
            caps.aux       [ci] = state.args[n]\
        end\
        return true, si, ci + 1\
    end\
end\
for _, v in pairs{ \
    \"Cb\", \"Cc\", \"Cp\"\
} do\
    compilers[v] = load(([=[\
    return function (pt, ccache)\
        local this_aux = pt.aux\
        return function (sbj, si, caps, ci, state)\
            caps.kind      [ci] = \"XXXX\"\
            caps.bounds    [ci] = si\
            caps.openclose [ci] = si\
            caps.aux       [ci] = this_aux or false\
            return true, si, ci + 1\
        end\
    end]=]):gsub(\"XXXX\", v), v..\" compiler\")(expose)\
end\
compilers[\"/zero\"] = function (pt, ccache)\
    local matcher = compile(pt.pattern, ccache)\
    return function (sbj, si, caps, ci, state)\
        local success, nsi = matcher(sbj, si, caps, ci, state)\
        clear_captures(caps.aux, ci)\
        return success, nsi, ci\
    end\
end\
local function pack_Cmt_caps(i,...) return i, t_pack(...) end\
compilers[\"Cmt\"] = function (pt, ccache)\
    local matcher, func = compile(pt.pattern, ccache), pt.aux\
    return function (sbj, si, caps, ci, state)\
        local success, Cmt_si, Cmt_ci = matcher(sbj, si, caps, ci, state)\
        if not success then \
            clear_captures(caps.aux, ci)\
            return false, si, ci\
        end\
        local final_si, values \
        if Cmt_ci == ci then\
            final_si, values = pack_Cmt_caps(\
                func(sbj, Cmt_si, s_sub(sbj, si, Cmt_si - 1))\
            )\
        else\
            clear_captures(caps.aux, Cmt_ci)\
            clear_captures(caps.kind, Cmt_ci)\
            local cps, _, nn = evaluate(caps, sbj, ci)\
                        final_si, values = pack_Cmt_caps(\
                func(sbj, Cmt_si, t_unpack(cps, 1, nn))\
            )\
        end\
        if not final_si then \
            return false, si, ci\
        end\
        if final_si == true then final_si = Cmt_si end\
        if type(final_si) == \"number\"\
        and si <= final_si \
        and final_si <= #sbj + 1 \
        then\
            local kind, bounds, openclose, aux \
                = caps.kind, caps.bounds, caps.openclose, caps.aux\
            for i = 1, values.n do\
                kind      [ci] = \"value\"\
                bounds    [ci] = si\
                if values[i] == nil then\
                    caps.openclose [ci] = 1/0\
                    caps.aux       [ci] = 1/0\
                else\
                    caps.openclose [ci] = final_si\
                    caps.aux       [ci] = values[i]\
                end\
                ci = ci + 1\
            end\
        elseif type(final_si) == \"number\" then\
            error\"Index out of bounds returned by match-time capture.\"\
        else\
            error(\"Match time capture must return a number, a boolean or nil\"\
                ..\" as first argument, or nothing at all.\")\
        end\
        return true, final_si, ci\
    end\
end\
compilers[\"string\"] = function (pt, ccache)\
    local S = pt.aux\
    local N = #S\
    return function(sbj, si, caps, ci, state)\
        local in_1 = si - 1\
        for i = 1, N do\
            local c\
            c = s_byte(sbj,in_1 + i)\
            if c ~= S[i] then\
                return false, si, ci\
            end\
        end\
        return true, si + N, ci\
    end\
end\
compilers[\"char\"] = function (pt, ccache)\
    return load(([=[\
        local s_byte, s_char = ...\
        return function(sbj, si, caps, ci, state)\
            local c, nsi = s_byte(sbj, si), si + 1\
            if c ~= __C0__ then\
                return false, si, ci\
            end\
            return true, nsi, ci\
        end]=]):gsub(\"__C0__\", tostring(pt.aux)))(s_byte, (\"\").char)\
end\
local\
function truecompiled (sbj, si, caps, ci, state)\
    return true, si, ci\
end\
compilers[\"true\"] = function (pt)\
    return truecompiled\
end\
local\
function falsecompiled (sbj, si, caps, ci, state)\
    return false, si, ci\
end\
compilers[\"false\"] = function (pt)\
    return falsecompiled\
end\
local\
function eoscompiled (sbj, si, caps, ci, state)\
    return si > #sbj, si, ci\
end\
compilers[\"eos\"] = function (pt)\
    return eoscompiled\
end\
local\
function onecompiled (sbj, si, caps, ci, state)\
    local char, _ = s_byte(sbj, si), si + 1\
    if char\
    then return true, si + 1, ci\
    else return false, si, ci end\
end\
compilers[\"one\"] = function (pt)\
    return onecompiled\
end\
compilers[\"any\"] = function (pt)\
    local N = pt.aux\
    if N == 1 then\
        return onecompiled\
    else\
        N = pt.aux - 1\
        return function (sbj, si, caps, ci, state)\
            local n = si + N\
            if n <= #sbj then\
                return true, n + 1, ci\
            else\
                return false, si, ci\
            end\
        end\
    end\
end\
do\
    local function checkpatterns(g)\
        for k,v in pairs(g.aux) do\
            if not LL_ispattern(v) then\
                error((\"rule 'A' is not a pattern\"):gsub(\"A\", tostring(k)))\
            end\
        end\
    end\
    compilers[\"grammar\"] = function (pt, ccache)\
        checkpatterns(pt)\
        local gram = map_all(pt.aux, compile, ccache)\
        local start = gram[1]\
        return function (sbj, si, caps, ci, state)\
            t_insert(state.grammars, gram)\
            local success, nsi, ci = start(sbj, si, caps, ci, state)\
            t_remove(state.grammars)\
            return success, nsi, ci\
        end\
    end\
end\
local dummy_acc = {kind={}, bounds={}, openclose={}, aux={}}\
compilers[\"behind\"] = function (pt, ccache)\
    local matcher, N = compile(pt.pattern, ccache), pt.aux\
    return function (sbj, si, caps, ci, state)\
        if si <= N then return false, si, ci end\
        local success = matcher(sbj, si - N, dummy_acc, ci, state)\
        dummy_acc.aux = {}\
        return success, si, ci\
    end\
end\
compilers[\"range\"] = function (pt)\
    local ranges = pt.aux\
    return function (sbj, si, caps, ci, state)\
        local char, nsi = s_byte(sbj, si), si + 1\
        for i = 1, #ranges do\
            local r = ranges[i]\
            if char and r[char]\
            then return true, nsi, ci end\
        end\
        return false, si, ci\
    end\
end\
compilers[\"set\"] = function (pt)\
    local s = pt.aux\
    return function (sbj, si, caps, ci, state)\
        local char, nsi = s_byte(sbj, si), si + 1\
        if s[char]\
        then return true, nsi, ci\
        else return false, si, ci end\
    end\
end\
compilers[\"range\"] = compilers.set\
compilers[\"ref\"] = function (pt, ccache)\
    local name = pt.aux\
    local ref\
    return function (sbj, si, caps, ci, state)\
        if not ref then\
            if #state.grammars == 0 then\
                error((\"rule 'XXXX' used outside a grammar\"):gsub(\"XXXX\", tostring(name)))\
            elseif not state.grammars[#state.grammars][name] then\
                error((\"rule 'XXXX' undefined in given grammar\"):gsub(\"XXXX\", tostring(name)))\
            end\
            ref = state.grammars[#state.grammars][name]\
        end\
            local success, nsi, nci = ref(sbj, si, caps, ci, state)\
        return success, nsi, nci\
    end\
end\
local choice_tpl = [=[\
            success, si, ci = XXXX(sbj, si, caps, ci, state)\
            if success then\
                return true, si, ci\
            else\
            end]=]\
local function flatten(kind, pt, ccache)\
    if pt[2].pkind == kind then\
        return compile(pt[1], ccache), flatten(kind, pt[2], ccache)\
    else\
        return compile(pt[1], ccache), compile(pt[2], ccache)\
    end\
end\
compilers[\"choice\"] = function (pt, ccache)\
    local choices = {flatten(\"choice\", pt, ccache)}\
    local names, chunks = {}, {}\
    for i = 1, #choices do\
        local m = \"ch\"..i\
        names[#names + 1] = m\
        chunks[ #names  ] = choice_tpl:gsub(\"XXXX\", m)\
    end\
    names[#names + 1] = \"clear_captures\"\
    choices[ #names ] = clear_captures\
    local compiled = t_concat{\
        \"local \", t_concat(names, \", \"), [=[ = ...\
        return function (sbj, si, caps, ci, state)\
            local aux, success = caps.aux, false\
            ]=],\
            t_concat(chunks,\"\\n\"),[=[--\
            return false, si, ci\
        end]=]\
    }\
    return load(compiled, \"Choice\")(t_unpack(choices))\
end\
local sequence_tpl = [=[\
            success, si, ci = XXXX(sbj, si, caps, ci, state)\
            if not success then\
                return false, ref_si, ref_ci\
            end]=]\
compilers[\"sequence\"] = function (pt, ccache)\
    local sequence = {flatten(\"sequence\", pt, ccache)}\
    local names, chunks = {}, {}\
    for i = 1, #sequence do\
        local m = \"seq\"..i\
        names[#names + 1] = m\
        chunks[ #names  ] = sequence_tpl:gsub(\"XXXX\", m)\
    end\
    names[#names + 1] = \"clear_captures\"\
    sequence[ #names ] = clear_captures\
    local compiled = t_concat{\
        \"local \", t_concat(names, \", \"), [=[ = ...\
        return function (sbj, si, caps, ci, state)\
            local ref_si, ref_ci, success = si, ci\
            ]=],\
            t_concat(chunks,\"\\n\"),[=[\
            return true, si, ci\
        end]=]\
    }\
   return load(compiled, \"Sequence\")(t_unpack(sequence))\
end\
compilers[\"at most\"] = function (pt, ccache)\
    local matcher, n = compile(pt.pattern, ccache), pt.aux\
    n = -n\
    return function (sbj, si, caps, ci, state)\
        local success = true\
        for i = 1, n do\
            success, si, ci = matcher(sbj, si, caps, ci, state)\
            if not success then \
                break\
            end\
        end\
        return true, si, ci\
    end\
end\
compilers[\"at least\"] = function (pt, ccache)\
    local matcher, n = compile(pt.pattern, ccache), pt.aux\
    if n == 0 then\
        return function (sbj, si, caps, ci, state)\
            local last_si, last_ci\
            while true do\
                local success\
                last_si, last_ci = si, ci\
                success, si, ci = matcher(sbj, si, caps, ci, state)\
                if not success then                     \
                    si, ci = last_si, last_ci\
                    break\
                end\
            end\
            return true, si, ci\
        end\
    elseif n == 1 then\
        return function (sbj, si, caps, ci, state)\
            local last_si, last_ci\
            local success = true\
            success, si, ci = matcher(sbj, si, caps, ci, state)\
            if not success then\
                return false, si, ci\
            end\
            while true do\
                local success\
                last_si, last_ci = si, ci\
                success, si, ci = matcher(sbj, si, caps, ci, state)\
                if not success then                     \
                    si, ci = last_si, last_ci\
                    break\
                end\
            end\
            return true, si, ci\
        end\
    else\
        return function (sbj, si, caps, ci, state)\
            local last_si, last_ci\
            local success = true\
            for _ = 1, n do\
                success, si, ci = matcher(sbj, si, caps, ci, state)\
                if not success then\
                    return false, si, ci\
                end\
            end\
            while true do\
                local success\
                last_si, last_ci = si, ci\
                success, si, ci = matcher(sbj, si, caps, ci, state)\
                if not success then                     \
                    si, ci = last_si, last_ci\
                    break\
                end\
            end\
            return true, si, ci\
        end\
    end\
end\
compilers[\"unm\"] = function (pt, ccache)\
    if pt.pkind == \"any\" and pt.aux == 1 then\
        return eoscompiled\
    end\
    local matcher = compile(pt.pattern, ccache)\
    return function (sbj, si, caps, ci, state)\
        local success, _, _ = matcher(sbj, si, caps, ci, state)\
        return not success, si, ci\
    end\
end\
compilers[\"lookahead\"] = function (pt, ccache)\
    local matcher = compile(pt.pattern, ccache)\
    return function (sbj, si, caps, ci, state)\
        local success, _, _ = matcher(sbj, si, caps, ci, state)\
        return success, si, ci\
    end\
end\
end\
\
end\
end\
--=============================================================================\
do local _ENV = _ENV\
packages['datastructures'] = function (...)\
local getmetatable, pairs, setmetatable, type\
    = getmetatable, pairs, setmetatable, type\
local m, t , u = require\"math\", require\"table\", require\"util\"\
local compat = require\"compat\"\
local ffi if compat.luajit then\
    ffi = require\"ffi\"\
end\
local _ENV = u.noglobals() ----------------------------------------------------\
local   extend,   load, u_max\
    = u.extend, u.load, u.max\
local m_max, t_concat, t_insert, t_sort\
    = m.max, t.concat, t.insert, t.sort\
local structfor = {}\
local byteset_new, isboolset, isbyteset\
local byteset_mt = {}\
local\
function byteset_constructor (upper)\
    local set = setmetatable(load(t_concat{\
        \"return{ [0]=false\",\
        (\", false\"):rep(upper),\
        \" }\"\
    })(),\
    byteset_mt)\
    return set\
end\
if compat.jit then\
    local struct, boolset_constructor = {v={}}\
    function byteset_mt.__index(s,i)\
        if i == nil or i > s.upper then return nil end\
        return s.v[i]\
    end\
    function byteset_mt.__len(s)\
        return s.upper\
    end\
    function byteset_mt.__newindex(s,i,v)\
        s.v[i] = v\
    end\
    boolset_constructor = ffi.metatype('struct { int upper; bool v[?]; }', byteset_mt)\
    function byteset_new (t)\
        if type(t) == \"number\" then\
            local res = boolset_constructor(t+1)\
            res.upper = t\
            return res\
        end\
        local upper = u_max(t)\
        struct.upper = upper\
        if upper > 255 then error\"bool_set overflow\" end\
        local set = boolset_constructor(upper+1)\
        set.upper = upper\
        for i = 1, #t do set[t[i]] = true end\
        return set\
    end\
    function isboolset(s) return type(s)==\"cdata\" and ffi.istype(s, boolset_constructor) end\
    isbyteset = isboolset\
else\
    function byteset_new (t)\
        if type(t) == \"number\" then return byteset_constructor(t) end\
        local set = byteset_constructor(u_max(t))\
        for i = 1, #t do set[t[i]] = true end\
        return set\
    end\
    function isboolset(s) return false end\
    function isbyteset (s)\
        return getmetatable(s) == byteset_mt\
    end\
end\
local\
function byterange_new (low, high)\
    high = ( low <= high ) and high or -1\
    local set = byteset_new(high)\
    for i = low, high do\
        set[i] = true\
    end\
    return set\
end\
local tmpa, tmpb ={}, {}\
local\
function set_if_not_yet (s, dest)\
    if type(s) == \"number\" then\
        dest[s] = true\
        return dest\
    else\
        return s\
    end\
end\
local\
function clean_ab (a,b)\
    tmpa[a] = nil\
    tmpb[b] = nil\
end\
local\
function byteset_union (a ,b)\
    local upper = m_max(\
        type(a) == \"number\" and a or #a,\
        type(b) == \"number\" and b or #b\
    )\
    local A, B\
        = set_if_not_yet(a, tmpa)\
        , set_if_not_yet(b, tmpb)\
    local res = byteset_new(upper)\
    for i = 0, upper do\
        res[i] = A[i] or B[i] or false\
    end\
    clean_ab(a,b)\
    return res\
end\
local\
function byteset_difference (a, b)\
    local res = {}\
    for i = 0, 255 do\
        res[i] = a[i] and not b[i]\
    end\
    return res\
end\
local\
function byteset_tostring (s)\
    local list = {}\
    for i = 0, 255 do\
        list[#list+1] = (s[i] == true) and i or nil\
    end\
    return t_concat(list,\", \")\
end\
structfor.binary = {\
    set ={\
        new = byteset_new,\
        union = byteset_union,\
        difference = byteset_difference,\
        tostring = byteset_tostring\
    },\
    Range = byterange_new,\
    isboolset = isboolset,\
    isbyteset = isbyteset,\
    isset = isbyteset\
}\
local set_mt = {}\
local\
function set_new (t)\
    local set = setmetatable({}, set_mt)\
    for i = 1, #t do set[t[i]] = true end\
    return set\
end\
local -- helper for the union code.\
function add_elements(a, res)\
    for k in pairs(a) do res[k] = true end\
    return res\
end\
local\
function set_union (a, b)\
    a, b = (type(a) == \"number\") and set_new{a} or a\
         , (type(b) == \"number\") and set_new{b} or b\
    local res = set_new{}\
    add_elements(a, res)\
    add_elements(b, res)\
    return res\
end\
local\
function set_difference(a, b)\
    local list = {}\
    a, b = (type(a) == \"number\") and set_new{a} or a\
         , (type(b) == \"number\") and set_new{b} or b\
    for el in pairs(a) do\
        if a[el] and not b[el] then\
            list[#list+1] = el\
        end\
    end\
    return set_new(list)\
end\
local\
function set_tostring (s)\
    local list = {}\
    for el in pairs(s) do\
        t_insert(list,el)\
    end\
    t_sort(list)\
    return t_concat(list, \",\")\
end\
local\
function isset (s)\
    return (getmetatable(s) == set_mt)\
end\
local\
function range_new (start, finish)\
    local list = {}\
    for i = start, finish do\
        list[#list + 1] = i\
    end\
    return set_new(list)\
end\
structfor.other = {\
    set = {\
        new = set_new,\
        union = set_union,\
        tostring = set_tostring,\
        difference = set_difference,\
    },\
    Range = range_new,\
    isboolset = isboolset,\
    isbyteset = isbyteset,\
    isset = isset,\
    isrange = function(a) return false end\
}\
return function(Builder, LL)\
    local cs = (Builder.options or {}).charset or \"binary\"\
    if type(cs) == \"string\" then\
        cs = (cs == \"binary\") and \"binary\" or \"other\"\
    else\
        cs = cs.binary and \"binary\" or \"other\"\
    end\
    return extend(Builder, structfor[cs])\
end\
\
end\
end\
--=============================================================================\
do local _ENV = _ENV\
packages['charsets'] = function (...)\
\
local s, t, u = require\"string\", require\"table\", require\"util\"\
local _ENV = u.noglobals() ----------------------------------------------------\
local copy = u.copy\
local s_char, s_sub, s_byte, t_concat, t_insert\
    = s.char, s.sub, s.byte, t.concat, t.insert\
local\
function utf8_offset (byte)\
    if byte < 128 then return 0, byte\
    elseif byte < 192 then\
        error(\"Byte values between 0x80 to 0xBF cannot start a multibyte sequence\")\
    elseif byte < 224 then return 1, byte - 192\
    elseif byte < 240 then return 2, byte - 224\
    elseif byte < 248 then return 3, byte - 240\
    elseif byte < 252 then return 4, byte - 248\
    elseif byte < 254 then return 5, byte - 252\
    else\
        error(\"Byte values between 0xFE and OxFF cannot start a multibyte sequence\")\
    end\
end\
local\
function utf8_validate (subject, start, finish)\
    start = start or 1\
    finish = finish or #subject\
    local offset, char\
        = 0\
    for i = start,finish do\
        local b = s_byte(subject,i)\
        if offset == 0 then\
            char = i\
            success, offset = pcall(utf8_offset, b)\
            if not success then return false, char - 1 end\
        else\
            if not (127 < b and b < 192) then\
                return false, char - 1\
            end\
            offset = offset -1\
        end\
    end\
    if offset ~= 0 then return nil, char - 1 end -- Incomplete input.\
    return true, finish\
end\
local\
function utf8_next_int (subject, i)\
    i = i and i+1 or 1\
    if i > #subject then return end\
    local c = s_byte(subject, i)\
    local offset, val = utf8_offset(c)\
    for i = i+1, i+offset do\
        c = s_byte(subject, i)\
        val = val * 64 + (c-128)\
    end\
  return i + offset, i, val\
end\
local\
function utf8_next_char (subject, i)\
    i = i and i+1 or 1\
    if i > #subject then return end\
    local offset = utf8_offset(s_byte(subject,i))\
    return i + offset, i, s_sub(subject, i, i + offset)\
end\
local\
function utf8_split_int (subject)\
    local chars = {}\
    for _, _, c in utf8_next_int, subject do\
        t_insert(chars,c)\
    end\
    return chars\
end\
local\
function utf8_split_char (subject)\
    local chars = {}\
    for _, _, c in utf8_next_char, subject do\
        t_insert(chars,c)\
    end\
    return chars\
end\
local\
function utf8_get_int(subject, i)\
    if i > #subject then return end\
    local c = s_byte(subject, i)\
    local offset, val = utf8_offset(c)\
    for i = i+1, i+offset do\
        c = s_byte(subject, i)\
        val = val * 64 + ( c - 128 )\
    end\
    return val, i + offset + 1\
end\
local\
function split_generator (get)\
    if not get then return end\
    return function(subject)\
        local res = {}\
        local o, i = true\
        while o do\
            o,i = get(subject, i)\
            res[#res] = o\
        end\
        return res\
    end\
end\
local\
function merge_generator (char)\
    if not char then return end\
    return function(ary)\
        local res = {}\
        for i = 1, #ary do\
            t_insert(res,char(ary[i]))\
        end\
        return t_concat(res)\
    end\
end\
local\
function utf8_get_int2 (subject, i)\
    local byte, b5, b4, b3, b2, b1 = s_byte(subject, i)\
    if byte < 128 then return byte, i + 1\
    elseif byte < 192 then\
        error(\"Byte values between 0x80 to 0xBF cannot start a multibyte sequence\")\
    elseif byte < 224 then\
        return (byte - 192)*64 + s_byte(subject, i+1), i+2\
    elseif byte < 240 then\
            b2, b1 = s_byte(subject, i+1, i+2)\
        return (byte-224)*4096 + b2%64*64 + b1%64, i+3\
    elseif byte < 248 then\
        b3, b2, b1 = s_byte(subject, i+1, i+2, 1+3)\
        return (byte-240)*262144 + b3%64*4096 + b2%64*64 + b1%64, i+4\
    elseif byte < 252 then\
        b4, b3, b2, b1 = s_byte(subject, i+1, i+2, 1+3, i+4)\
        return (byte-248)*16777216 + b4%64*262144 + b3%64*4096 + b2%64*64 + b1%64, i+5\
    elseif byte < 254 then\
        b5, b4, b3, b2, b1 = s_byte(subject, i+1, i+2, 1+3, i+4, i+5)\
        return (byte-252)*1073741824 + b5%64*16777216 + b4%64*262144 + b3%64*4096 + b2%64*64 + b1%64, i+6\
    else\
        error(\"Byte values between 0xFE and OxFF cannot start a multibyte sequence\")\
    end\
end\
local\
function utf8_get_char(subject, i)\
    if i > #subject then return end\
    local offset = utf8_offset(s_byte(subject,i))\
    return s_sub(subject, i, i + offset), i + offset + 1\
end\
local\
function utf8_char(c)\
    if     c < 128 then\
        return                                                                               s_char(c)\
    elseif c < 2048 then\
        return                                                          s_char(192 + c/64, 128 + c%64)\
    elseif c < 55296 or 57343 < c and c < 65536 then\
        return                                         s_char(224 + c/4096, 128 + c/64%64, 128 + c%64)\
    elseif c < 2097152 then\
        return                      s_char(240 + c/262144, 128 + c/4096%64, 128 + c/64%64, 128 + c%64)\
    elseif c < 67108864 then\
        return s_char(248 + c/16777216, 128 + c/262144%64, 128 + c/4096%64, 128 + c/64%64, 128 + c%64)\
    elseif c < 2147483648 then\
        return s_char( 252 + c/1073741824,\
                   128 + c/16777216%64, 128 + c/262144%64, 128 + c/4096%64, 128 + c/64%64, 128 + c%64)\
    end\
    error(\"Bad Unicode code point: \"..c..\".\")\
end\
local\
function binary_validate (subject, start, finish)\
    start = start or 1\
    finish = finish or #subject\
    return true, finish\
end\
local\
function binary_next_int (subject, i)\
    i = i and i+1 or 1\
    if i >= #subject then return end\
    return i, i, s_sub(subject, i, i)\
end\
local\
function binary_next_char (subject, i)\
    i = i and i+1 or 1\
    if i > #subject then return end\
    return i, i, s_byte(subject,i)\
end\
local\
function binary_split_int (subject)\
    local chars = {}\
    for i = 1, #subject do\
        t_insert(chars, s_byte(subject,i))\
    end\
    return chars\
end\
local\
function binary_split_char (subject)\
    local chars = {}\
    for i = 1, #subject do\
        t_insert(chars, s_sub(subject,i,i))\
    end\
    return chars\
end\
local\
function binary_get_int(subject, i)\
    return s_byte(subject, i), i + 1\
end\
local\
function binary_get_char(subject, i)\
    return s_sub(subject, i, i), i + 1\
end\
local charsets = {\
    binary = {\
        name = \"binary\",\
        binary = true,\
        validate   = binary_validate,\
        split_char = binary_split_char,\
        split_int  = binary_split_int,\
        next_char  = binary_next_char,\
        next_int   = binary_next_int,\
        get_char   = binary_get_char,\
        get_int    = binary_get_int,\
        tochar    = s_char\
    },\
    [\"UTF-8\"] = {\
        name = \"UTF-8\",\
        validate   = utf8_validate,\
        split_char = utf8_split_char,\
        split_int  = utf8_split_int,\
        next_char  = utf8_next_char,\
        next_int   = utf8_next_int,\
        get_char   = utf8_get_char,\
        get_int    = utf8_get_int\
    }\
}\
return function (Builder)\
    local cs = Builder.options.charset or \"binary\"\
    if charsets[cs] then\
        Builder.charset = copy(charsets[cs])\
        Builder.binary_split_int = binary_split_int\
    else\
        error(\"NYI: custom charsets\")\
    end\
end\
\
end\
end\
--=============================================================================\
do local _ENV = _ENV\
packages['re'] = function (...)\
\
return function(Builder, LL)\
local tonumber, type, print, error = tonumber, type, print, error\
local setmetatable = setmetatable\
local m = LL\
local mm = m\
local mt = getmetatable(mm.P(0))\
local version = _VERSION\
if version == \"Lua 5.2\" then _ENV = nil end\
local any = m.P(1)\
local Predef = { nl = m.P\"\\n\" }\
local mem\
local fmem\
local gmem\
local function updatelocale ()\
  mm.locale(Predef)\
  Predef.a = Predef.alpha\
  Predef.c = Predef.cntrl\
  Predef.d = Predef.digit\
  Predef.g = Predef.graph\
  Predef.l = Predef.lower\
  Predef.p = Predef.punct\
  Predef.s = Predef.space\
  Predef.u = Predef.upper\
  Predef.w = Predef.alnum\
  Predef.x = Predef.xdigit\
  Predef.A = any - Predef.a\
  Predef.C = any - Predef.c\
  Predef.D = any - Predef.d\
  Predef.G = any - Predef.g\
  Predef.L = any - Predef.l\
  Predef.P = any - Predef.p\
  Predef.S = any - Predef.s\
  Predef.U = any - Predef.u\
  Predef.W = any - Predef.w\
  Predef.X = any - Predef.x\
  mem = {}    -- restart memoization\
  fmem = {}\
  gmem = {}\
  local mt = {__mode = \"v\"}\
  setmetatable(mem, mt)\
  setmetatable(fmem, mt)\
  setmetatable(gmem, mt)\
end\
updatelocale()\
local function getdef (id, defs)\
  local c = defs and defs[id]\
  if not c then error(\"undefined name: \" .. id) end\
  return c\
end\
local function patt_error (s, i)\
  local msg = (#s < i + 20) and s:sub(i)\
                             or s:sub(i,i+20) .. \"...\"\
  msg = (\"pattern error near '%s'\"):format(msg)\
  error(msg, 2)\
end\
local function mult (p, n)\
  local np = mm.P(true)\
  while n >= 1 do\
    if n%2 >= 1 then np = np * p end\
    p = p * p\
    n = n/2\
  end\
  return np\
end\
local function equalcap (s, i, c)\
  if type(c) ~= \"string\" then return nil end\
  local e = #c + i\
  if s:sub(i, e - 1) == c then return e else return nil end\
end\
local S = (Predef.space + \"--\" * (any - Predef.nl)^0)^0\
local name = m.R(\"AZ\", \"az\", \"__\") * m.R(\"AZ\", \"az\", \"__\", \"09\")^0\
local arrow = S * \"<-\"\
local seq_follow = m.P\"/\" + \")\" + \"}\" + \":}\" + \"~}\" + \"|}\" + (name * arrow) + -1\
name = m.C(name)\
local Def = name * m.Carg(1)\
local num = m.C(m.R\"09\"^1) * S / tonumber\
local String = \"'\" * m.C((any - \"'\")^0) * \"'\" +\
               '\"' * m.C((any - '\"')^0) * '\"'\
local defined = \"%\" * Def / function (c,Defs)\
  local cat =  Defs and Defs[c] or Predef[c]\
  if not cat then error (\"name '\" .. c .. \"' undefined\") end\
  return cat\
end\
local Range = m.Cs(any * (m.P\"-\"/\"\") * (any - \"]\")) / mm.R\
local item = defined + Range + m.C(any)\
local Class =\
    \"[\"\
  * (m.C(m.P\"^\"^-1))    -- optional complement symbol\
  * m.Cf(item * (item - \"]\")^0, mt.__add) /\
                          function (c, p) return c == \"^\" and any - p or p end\
  * \"]\"\
local function adddef (t, k, exp)\
  if t[k] then\
    error(\"'\"..k..\"' already defined as a rule\")\
  else\
    t[k] = exp\
  end\
  return t\
end\
local function firstdef (n, r) return adddef({n}, n, r) end\
local function NT (n, b)\
  if not b then\
    error(\"rule '\"..n..\"' used outside a grammar\")\
  else return mm.V(n)\
  end\
end\
local exp = m.P{ \"Exp\",\
  Exp = S * ( m.V\"Grammar\"\
            + m.Cf(m.V\"Seq\" * (\"/\" * S * m.V\"Seq\")^0, mt.__add) );\
  Seq = m.Cf(m.Cc(m.P\"\") * m.V\"Prefix\"^0 , mt.__mul)\
        * (m.L(seq_follow) + patt_error);\
  Prefix = \"&\" * S * m.V\"Prefix\" / mt.__len\
         + \"!\" * S * m.V\"Prefix\" / mt.__unm\
         + m.V\"Suffix\";\
  Suffix = m.Cf(m.V\"Primary\" * S *\
          ( ( m.P\"+\" * m.Cc(1, mt.__pow)\
            + m.P\"*\" * m.Cc(0, mt.__pow)\
            + m.P\"?\" * m.Cc(-1, mt.__pow)\
            + \"^\" * ( m.Cg(num * m.Cc(mult))\
                    + m.Cg(m.C(m.S\"+-\" * m.R\"09\"^1) * m.Cc(mt.__pow))\
                    )\
            + \"->\" * S * ( m.Cg((String + num) * m.Cc(mt.__div))\
                         + m.P\"{}\" * m.Cc(nil, m.Ct)\
                         + m.Cg(Def / getdef * m.Cc(mt.__div))\
                         )\
            + \"=>\" * S * m.Cg(Def / getdef * m.Cc(m.Cmt))\
            ) * S\
          )^0, function (a,b,f) return f(a,b) end );\
  Primary = \"(\" * m.V\"Exp\" * \")\"\
            + String / mm.P\
            + Class\
            + defined\
            + \"{:\" * (name * \":\" + m.Cc(nil)) * m.V\"Exp\" * \":}\" /\
                     function (n, p) return mm.Cg(p, n) end\
            + \"=\" * name / function (n) return mm.Cmt(mm.Cb(n), equalcap) end\
            + m.P\"{}\" / mm.Cp\
            + \"{~\" * m.V\"Exp\" * \"~}\" / mm.Cs\
            + \"{|\" * m.V\"Exp\" * \"|}\" / mm.Ct\
            + \"{\" * m.V\"Exp\" * \"}\" / mm.C\
            + m.P\".\" * m.Cc(any)\
            + (name * -arrow + \"<\" * name * \">\") * m.Cb(\"G\") / NT;\
  Definition = name * arrow * m.V\"Exp\";\
  Grammar = m.Cg(m.Cc(true), \"G\") *\
            m.Cf(m.V\"Definition\" / firstdef * m.Cg(m.V\"Definition\")^0,\
              adddef) / mm.P\
}\
local pattern = S * m.Cg(m.Cc(false), \"G\") * exp / mm.P * (-any + patt_error)\
local function compile (p, defs)\
  if mm.type(p) == \"pattern\" then return p end   -- already compiled\
  local cp = pattern:match(p, 1, defs)\
  if not cp then error(\"incorrect pattern\", 3) end\
  return cp\
end\
local function match (s, p, i)\
  local cp = mem[p]\
  if not cp then\
    cp = compile(p)\
    mem[p] = cp\
  end\
  return cp:match(s, i or 1)\
end\
local function find (s, p, i)\
  local cp = fmem[p]\
  if not cp then\
    cp = compile(p) / 0\
    cp = mm.P{ mm.Cp() * cp * mm.Cp() + 1 * mm.V(1) }\
    fmem[p] = cp\
  end\
  local i, e = cp:match(s, i or 1)\
  if i then return i, e - 1\
  else return i\
  end\
end\
local function gsub (s, p, rep)\
  local g = gmem[p] or {}   -- ensure gmem[p] is not collected while here\
  gmem[p] = g\
  local cp = g[rep]\
  if not cp then\
    cp = compile(p)\
    cp = mm.Cs((cp / rep + 1)^0)\
    g[rep] = cp\
  end\
  return cp:match(s)\
end\
local re = {\
  compile = compile,\
  match = match,\
  find = find,\
  gsub = gsub,\
  updatelocale = updatelocale,\
}\
return re\
end\
end\
end\
--=============================================================================\
do local _ENV = _ENV\
packages['evaluator'] = function (...)\
\
local select, tonumber, tostring, type\
    = select, tonumber, tostring, type\
local s, t, u = require\"string\", require\"table\", require\"util\"\
local s_sub, t_concat\
    = s.sub, t.concat\
local t_unpack\
    = u.unpack\
local _ENV = u.noglobals() ----------------------------------------------------\
return function(Builder, LL) -- Decorator wrapper\
local eval = {}\
local\
function insert (caps, sbj, vals, ci, vi)\
    local openclose, kind = caps.openclose, caps.kind\
    while kind[ci] and openclose[ci] >= 0 do\
        ci, vi = eval[kind[ci]](caps, sbj, vals, ci, vi)\
    end\
    return ci, vi\
end\
function eval.C (caps, sbj, vals, ci, vi)\
    if caps.openclose[ci] > 0 then\
        vals[vi] = s_sub(sbj, caps.bounds[ci], caps.openclose[ci] - 1)\
        return ci + 1, vi + 1\
    end\
    vals[vi] = false -- pad it for now\
    local cj, vj = insert(caps, sbj, vals, ci + 1, vi + 1)\
    vals[vi] = s_sub(sbj, caps.bounds[ci], caps.bounds[cj] - 1)\
    return cj + 1, vj\
end\
local\
function lookback (caps, label, ci)\
    local aux, openclose, kind= caps.aux, caps.openclose, caps.kind\
    repeat\
        ci = ci - 1\
        local auxv, oc = aux[ci], openclose[ci]\
        if oc < 0 then ci = ci + oc end\
        if oc ~= 0 and kind[ci] == \"Clb\" and label == auxv then\
            return ci\
        end\
    until ci == 1\
    label = type(label) == \"string\" and \"'\"..label..\"'\" or tostring(label)\
    error(\"back reference \"..label..\" not found\")\
end\
function eval.Cb (caps, sbj, vals, ci, vi)\
    local Cb_ci = lookback(caps, caps.aux[ci], ci)\
    Cb_ci, vi = eval.Cg(caps, sbj, vals, Cb_ci, vi)\
    return ci + 1, vi\
end\
function eval.Cc (caps, sbj, vals, ci, vi)\
    local these_values = caps.aux[ci]\
    for i = 1, these_values.n do\
        vi, vals[vi] = vi + 1, these_values[i]\
    end\
    return ci + 1, vi\
end\
eval[\"Cf\"] = function() error(\"NYI: Cf\") end\
function eval.Cf (caps, sbj, vals, ci, vi)\
    if caps.openclose[ci] > 0 then\
        error\"No First Value\"\
    end\
    local func, Cf_vals, Cf_vi = caps.aux[ci], {}\
    ci = ci + 1\
    ci, Cf_vi = eval[caps.kind[ci]](caps, sbj, Cf_vals, ci, 1)\
    if Cf_vi == 1 then\
        error\"No first value\"\
    end\
    local result = Cf_vals[1]\
    while caps.kind[ci] and caps.openclose[ci] >= 0 do\
        ci, Cf_vi = eval[caps.kind[ci]](caps, sbj, Cf_vals, ci, 1)\
        result = func(result, t_unpack(Cf_vals, 1, Cf_vi - 1))\
    end\
    vals[vi] = result\
    return ci +1, vi + 1\
end\
function eval.Cg (caps, sbj, vals, ci, vi)\
    if caps.openclose[ci] > 0 then\
        vals[vi] = s_sub(sbj, caps.bounds[ci], caps.openclose[ci] - 1)\
        return ci + 1, vi + 1\
    end\
    local cj, vj = insert(caps, sbj, vals, ci + 1, vi)\
    if vj == vi then \
        vals[vj] = s_sub(sbj, caps.bounds[ci], caps.bounds[cj] - 1)\
        vj = vj + 1\
    end\
    return cj + 1, vj\
end\
function eval.Clb (caps, sbj, vals, ci, vi)\
    local oc = caps.openclose\
    if oc[ci] > 0 then\
        return ci + 1, vi \
    end\
    local depth = 0\
    repeat\
        if oc[ci] == 0 then depth = depth + 1\
        elseif oc[ci] < 0 then depth = depth - 1\
        end\
        ci = ci + 1\
    until depth == 0\
    return ci, vi\
end\
function eval.Cp (caps, sbj, vals, ci, vi)\
    vals[vi] = caps.bounds[ci]\
    return ci + 1, vi + 1\
end\
function eval.Ct (caps, sbj, vals, ci, vi)\
    local aux, openclose, kind = caps. aux, caps.openclose, caps.kind\
    local tbl_vals = {}\
    vals[vi] = tbl_vals\
    if openclose[ci] > 0 then\
        return ci + 1, vi + 1\
    end\
    local tbl_vi, Clb_vals = 1, {}\
    ci = ci + 1\
    while kind[ci] and openclose[ci] >= 0 do\
        if kind[ci] == \"Clb\" then\
            local label, Clb_vi = aux[ci], 1\
            ci, Clb_vi = eval.Cg(caps, sbj, Clb_vals, ci, 1)\
            if Clb_vi ~= 1 then tbl_vals[label] = Clb_vals[1] end\
        else\
            ci, tbl_vi =  eval[kind[ci]](caps, sbj, tbl_vals, ci, tbl_vi)\
        end\
    end\
    return ci + 1, vi + 1\
end\
local inf = 1/0\
function eval.value (caps, sbj, vals, ci, vi)\
    local val \
    if caps.aux[ci] ~= inf or caps.openclose[ci] ~= inf\
        then val = caps.aux[ci]\
    end\
    vals[vi] = val\
    return ci + 1, vi + 1\
end\
function eval.Cs (caps, sbj, vals, ci, vi)\
    if caps.openclose[ci] > 0 then\
        vals[vi] = s_sub(sbj, caps.bounds[ci], caps.openclose[ci] - 1)\
    else\
        local bounds, kind, openclose = caps.bounds, caps.kind, caps.openclose\
        local start, buffer, Cs_vals, bi, Cs_vi = bounds[ci], {}, {}, 1, 1\
        local last\
        ci = ci + 1\
        while openclose[ci] >= 0 do\
            last = bounds[ci]\
            buffer[bi] = s_sub(sbj, start, last - 1)\
            bi = bi + 1\
            ci, Cs_vi = eval[kind[ci]](caps, sbj, Cs_vals, ci, 1)\
            if Cs_vi > 1 then\
                buffer[bi] = Cs_vals[1]\
                bi = bi + 1\
                start = openclose[ci-1] > 0 and openclose[ci-1] or bounds[ci-1]\
            else\
                start = last\
            end\
        end\
        buffer[bi] = s_sub(sbj, start, bounds[ci] - 1)\
        vals[vi] = t_concat(buffer)\
    end\
    return ci + 1, vi + 1\
end\
local\
function insert_divfunc_results(acc, val_i, ...)\
    local n = select('#', ...)\
    for i = 1, n do\
        val_i, acc[val_i] = val_i + 1, select(i, ...)\
    end\
    return val_i\
end\
function eval.div_function (caps, sbj, vals, ci, vi)\
    local func = caps.aux[ci]\
    local params, divF_vi\
    if caps.openclose[ci] > 0 then\
        params, divF_vi = {s_sub(sbj, caps.bounds[ci], caps.openclose[ci] - 1)}, 2\
    else\
        params = {}\
        ci, divF_vi = insert(caps, sbj, params, ci + 1, 1)\
    end\
    ci = ci + 1 -- skip the closed or closing node.\
    vi = insert_divfunc_results(vals, vi, func(t_unpack(params, 1, divF_vi - 1)))\
    return ci, vi\
end\
function eval.div_number (caps, sbj, vals, ci, vi)\
    local this_aux = caps.aux[ci]\
    local divN_vals, divN_vi\
    if caps.openclose[ci] > 0 then\
        divN_vals, divN_vi = {s_sub(sbj, caps.bounds[ci], caps.openclose[ci] - 1)}, 2\
    else\
        divN_vals = {}\
        ci, divN_vi = insert(caps, sbj, divN_vals, ci + 1, 1)\
    end\
    ci = ci + 1 -- skip the closed or closing node.\
    if this_aux >= divN_vi then error(\"no capture '\"..this_aux..\"' in /number capture.\") end\
    vals[vi] = divN_vals[this_aux]\
    return ci, vi + 1\
end\
local function div_str_cap_refs (caps, ci)\
    local opcl = caps.openclose\
    local refs = {open=caps.bounds[ci]}\
    if opcl[ci] > 0 then\
        refs.close = opcl[ci]\
        return ci + 1, refs, 0\
    end\
    local first_ci = ci\
    local depth = 1\
    ci = ci + 1\
    repeat\
        local oc = opcl[ci]\
        if depth == 1  and oc >= 0 then refs[#refs+1] = ci end\
        if oc == 0 then \
            depth = depth + 1\
        elseif oc < 0 then\
            depth = depth - 1\
        end\
        ci = ci + 1\
    until depth == 0\
    refs.close = caps.bounds[ci - 1]\
    return ci, refs, #refs\
end\
function eval.div_string (caps, sbj, vals, ci, vi)\
    local n, refs\
    local cached\
    local cached, divS_vals = {}, {}\
    local the_string = caps.aux[ci]\
    ci, refs, n = div_str_cap_refs(caps, ci)\
    vals[vi] = the_string:gsub(\"%%([%d%%])\", function (d)\
        if d == \"%\" then return \"%\" end\
        d = tonumber(d)\
        if not cached[d] then\
            if d > n then\
                error(\"no capture at index \"..d..\" in /string capture.\")\
            end\
            if d == 0 then\
                cached[d] = s_sub(sbj, refs.open, refs.close - 1)\
            else\
                local _, vi = eval[caps.kind[refs[d]]](caps, sbj, divS_vals, refs[d], 1)\
                if vi == 1 then error(\"no values in capture at index\"..d..\" in /string capture.\") end\
                cached[d] = divS_vals[1]\
            end\
        end\
        return cached[d]\
    end)\
    return ci, vi + 1\
end\
function eval.div_table (caps, sbj, vals, ci, vi)\
    local this_aux = caps.aux[ci]\
    local key\
    if caps.openclose[ci] > 0 then\
        key =  s_sub(sbj, caps.bounds[ci], caps.openclose[ci] - 1)\
    else\
        local divT_vals, _ = {}\
        ci, _ = insert(caps, sbj, divT_vals, ci + 1, 1)\
        key = divT_vals[1]\
    end\
    ci = ci + 1\
    if this_aux[key] then\
        vals[vi] = this_aux[key]\
        return ci, vi + 1\
    else\
        return ci, vi\
    end\
end\
function LL.evaluate (caps, sbj, ci)\
    local vals = {}\
    local _,  vi = insert(caps, sbj, vals, ci, 1)\
    return vals, 1, vi - 1\
end\
end  -- Decorator wrapper\
\
end\
end\
--=============================================================================\
do local _ENV = _ENV\
packages['printers'] = function (...)\
return function(Builder, LL)\
local ipairs, pairs, print, tostring, type\
    = ipairs, pairs, print, tostring, type\
local s, t, u = require\"string\", require\"table\", require\"util\"\
local S_tostring = Builder.set.tostring\
local _ENV = u.noglobals() ----------------------------------------------------\
local s_char, s_sub, t_concat\
    = s.char, s.sub, t.concat\
local   expose,   load,   map\
    = u.expose, u.load, u.map\
local escape_index = {\
    [\"\\f\"] = \"\\\\f\",\
    [\"\\n\"] = \"\\\\n\",\
    [\"\\r\"] = \"\\\\r\",\
    [\"\\t\"] = \"\\\\t\",\
    [\"\\v\"] = \"\\\\v\",\
    [\"\\127\"] = \"\\\\ESC\"\
}\
local function flatten(kind, list)\
    if list[2].pkind == kind then\
        return list[1], flatten(kind, list[2])\
    else\
        return list[1], list[2]\
    end\
end\
for i = 0, 8 do escape_index[s_char(i)] = \"\\\\\"..i end\
for i = 14, 31 do escape_index[s_char(i)] = \"\\\\\"..i end\
local\
function escape( str )\
    return str:gsub(\"%c\", escape_index)\
end\
local\
function set_repr (set) \
    return s_char(load(\"return \"..S_tostring(set))())\
end\
local printers = {}\
local\
function LL_pprint (pt, offset, prefix)\
    return printers[pt.pkind](pt, offset, prefix)\
end\
function LL.pprint (pt0)\
    local pt = LL.P(pt0)\
    print\"\\nPrint pattern\"\
    LL_pprint(pt, \"\", \"\")\
    print\"--- /pprint\\n\"\
    return pt0\
end\
for k, v in pairs{\
    string       = [[ \"P( \\\"\"..escape(pt.as_is)..\"\\\" )\"       ]],\
    char         = [[ \"P( \\\"\"..escape(to_char(pt.aux))..\"\\\" )\"]],\
    [\"true\"]     = [[ \"P( true )\"                     ]],\
    [\"false\"]    = [[ \"P( false )\"                    ]],\
    eos          = [[ \"~EOS~\"                         ]],\
    one          = [[ \"P( one )\"                      ]],\
    any          = [[ \"P( \"..pt.aux..\" )\"             ]],\
    set          = [[ \"S( \"..'\"'..escape(set_repr(pt.aux))..'\"'..\" )\" ]],\
    [\"function\"] = [[ \"P( \"..pt.aux..\" )\"             ]],\
    ref = [[\
        \"V( \",\
            (type(pt.aux) == \"string\" and \"\\\"\"..pt.aux..\"\\\"\")\
                          or tostring(pt.aux)\
        , \" )\"\
        ]],\
    range = [[\
        \"R( \",\
            escape(t_concat(map(\
                pt.as_is,\
                function(e) return '\"'..e..'\"' end)\
            , \", \"))\
        ,\" )\"\
        ]]\
} do\
    printers[k] = load(([==[\
        local k, map, t_concat, to_char, escape, set_repr = ...\
        return function (pt, offset, prefix)\
            print(t_concat{offset,prefix,XXXX})\
        end\
    ]==]):gsub(\"XXXX\", v), k..\" printer\")(k, map, t_concat, s_char, escape, set_repr)\
end\
for k, v in pairs{\
    [\"behind\"] = [[ LL_pprint(pt.pattern, offset, \"B \") ]],\
    [\"at least\"] = [[ LL_pprint(pt.pattern, offset, pt.aux..\" ^ \") ]],\
    [\"at most\"] = [[ LL_pprint(pt.pattern, offset, pt.aux..\" ^ \") ]],\
    unm        = [[LL_pprint(pt.pattern, offset, \"- \")]],\
    lookahead  = [[LL_pprint(pt.pattern, offset, \"# \")]],\
    choice = [[\
        print(offset..prefix..\"+\")\
        local ch, i = {}, 1\
        while pt.pkind == \"choice\" do\
            ch[i], pt, i = pt[1], pt[2], i + 1\
        end\
        ch[i] = pt\
        map(ch, LL_pprint, offset..\" :\", \"\")\
        ]],\
    sequence = [=[\
        print(offset..prefix..\"*\")\
        local acc, p2 = {}\
        offset = offset .. \" |\"\
        while true do\
            if pt.pkind ~= \"sequence\" then -- last element\
                if pt.pkind == \"char\" then\
                    acc[#acc + 1] = pt.aux\
                    print(offset..'P( \"'..s.char(u.unpack(acc))..'\" )')\
                else\
                    if #acc ~= 0 then\
                        print(offset..'P( \"'..s.char(u.unpack(acc))..'\" )')\
                    end\
                    LL_pprint(pt, offset, \"\")\
                end\
                break\
            elseif pt[1].pkind == \"char\" then\
                acc[#acc + 1] = pt[1].aux\
            elseif #acc ~= 0 then\
                print(offset..'P( \"'..s.char(u.unpack(acc))..'\" )')\
                acc = {}\
                LL_pprint(pt[1], offset, \"\")\
            else\
                LL_pprint(pt[1], offset, \"\")\
            end\
            pt = pt[2]\
        end\
        ]=],\
    grammar   = [[\
        print(offset..prefix..\"Grammar\")\
        for k, pt in pairs(pt.aux) do\
            local prefix = ( type(k)~=\"string\"\
                             and tostring(k)\
                             or \"\\\"\"..k..\"\\\"\" )\
            LL_pprint(pt, offset..\"  \", prefix .. \" = \")\
        end\
    ]]\
} do\
    printers[k] = load(([[\
        local map, LL_pprint, pkind, s, u, flatten = ...\
        return function (pt, offset, prefix)\
            XXXX\
        end\
    ]]):gsub(\"XXXX\", v), k..\" printer\")(map, LL_pprint, type, s, u, flatten)\
end\
for _, cap in pairs{\"C\", \"Cs\", \"Ct\"} do\
    printers[cap] = function (pt, offset, prefix)\
        print(offset..prefix..cap)\
        LL_pprint(pt.pattern, offset..\"  \", \"\")\
    end\
end\
for _, cap in pairs{\"Cg\", \"Clb\", \"Cf\", \"Cmt\", \"div_number\", \"/zero\", \"div_function\", \"div_table\"} do\
    printers[cap] = function (pt, offset, prefix)\
        print(offset..prefix..cap..\" \"..tostring(pt.aux or \"\"))\
        LL_pprint(pt.pattern, offset..\"  \", \"\")\
    end\
end\
printers[\"div_string\"] = function (pt, offset, prefix)\
    print(offset..prefix..'/string \"'..tostring(pt.aux or \"\")..'\"')\
    LL_pprint(pt.pattern, offset..\"  \", \"\")\
end\
for _, cap in pairs{\"Carg\", \"Cp\"} do\
    printers[cap] = function (pt, offset, prefix)\
        print(offset..prefix..cap..\"( \"..tostring(pt.aux)..\" )\")\
    end\
end\
printers[\"Cb\"] = function (pt, offset, prefix)\
    print(offset..prefix..\"Cb( \\\"\"..pt.aux..\"\\\" )\")\
end\
printers[\"Cc\"] = function (pt, offset, prefix)\
    print(offset..prefix..\"Cc(\" ..t_concat(map(pt.aux, tostring),\", \")..\" )\")\
end\
local cprinters = {}\
local padding = \"   \"\
local function padnum(n)\
    n = tostring(n)\
    n = n ..\".\"..((\" \"):rep(4 - #n))\
    return n\
end\
local function _cprint(caps, ci, indent, sbj, n)\
    local openclose, kind = caps.openclose, caps.kind\
    indent = indent or 0\
    while kind[ci] and openclose[ci] >= 0 do\
        if caps.openclose[ci] > 0 then \
            print(t_concat({\
                            padnum(n),\
                            padding:rep(indent),\
                            caps.kind[ci],\
                            \": start = \", tostring(caps.bounds[ci]),\
                            \" finish = \", tostring(caps.openclose[ci]),\
                            caps.aux[ci] and \" aux = \" or \"\",\
                            caps.aux[ci] and (\
                                type(caps.aux[ci]) == \"string\" \
                                    and '\"'..tostring(caps.aux[ci])..'\"'\
                                or tostring(caps.aux[ci])\
                            ) or \"\",\
                            \" \\t\", s_sub(sbj, caps.bounds[ci], caps.openclose[ci] - 1)\
                        }))\
            if type(caps.aux[ci]) == \"table\" then expose(caps.aux[ci]) end\
        else\
            local kind = caps.kind[ci]\
            local start = caps.bounds[ci]\
            print(t_concat({\
                            padnum(n),\
                            padding:rep(indent), kind,\
                            \": start = \", start,\
                            caps.aux[ci] and \" aux = \" or \"\",\
                            caps.aux[ci] and (\
                                type(caps.aux[ci]) == \"string\" \
                                    and '\"'..tostring(caps.aux[ci])..'\"'\
                                or tostring(caps.aux[ci])\
                            ) or \"\"\
                        }))\
            ci, n = _cprint(caps, ci + 1, indent + 1, sbj, n + 1)\
            print(t_concat({\
                            padnum(n),\
                            padding:rep(indent),\
                            \"/\", kind,\
                            \" finish = \", tostring(caps.bounds[ci]),\
                            \" \\t\", s_sub(sbj, start, (caps.bounds[ci] or 1) - 1)\
                        }))\
        end\
        n = n + 1\
        ci = ci + 1\
    end\
    return ci, n\
end\
function LL.cprint (caps, ci, sbj)\
    ci = ci or 1\
    print\"\\nCapture Printer:\\n================\"\
    _cprint(caps, ci, 0, sbj, 1)\
    print\"================\\n/Cprinter\\n\"\
end\
return { pprint = LL.pprint,cprint = LL.cprint }\
end -- module wrapper ---------------------------------------------------------\
\
end\
end\
--=============================================================================\
do local _ENV = _ENV\
packages['compat'] = function (...)\
\
local _, debug, jit\
_, debug = pcall(require, \"debug\")\
_, jit = pcall(require, \"jit\")\
jit = _ and jit\
local compat = {\
    debug = debug,\
    lua51 = (_VERSION == \"Lua 5.1\") and not jit,\
    lua52 = _VERSION == \"Lua 5.2\",\
    luajit = jit and true or false,\
    jit = jit and jit.status(),\
    lua52_len = not #setmetatable({},{__len = function()end}),\
    proxies = pcall(function()\
        local prox = newproxy(true)\
        local prox2 = newproxy(prox)\
        assert (type(getmetatable(prox)) == \"table\" \
                and (getmetatable(prox)) == (getmetatable(prox2)))\
    end),\
    _goto = not not(loadstring or load)\"::R::\"\
}\
return compat\
\
end\
end\
--=============================================================================\
do local _ENV = _ENV\
packages['factorizer'] = function (...)\
local ipairs, pairs, print, setmetatable\
    = ipairs, pairs, print, setmetatable\
local u = require\"util\"\
local   id,   nop,   setify,   weakkey\
    = u.id, u.nop, u.setify, u.weakkey\
local _ENV = u.noglobals() ----------------------------------------------------\
local\
function process_booleans(a, b, opts)\
    local id, brk = opts.id, opts.brk\
    if a == id then return true, b\
    elseif b == id then return true, a\
    elseif a == brk then return true, brk\
    else return false end\
end\
local unary = setify{\
    \"unm\", \"lookahead\", \"C\", \"Cf\",\
    \"Cg\", \"Cs\", \"Ct\", \"/zero\"\
}\
local unary_aux = setify{\
    \"behind\", \"at least\", \"at most\", \"Clb\", \"Cmt\",\
    \"div_string\", \"div_number\", \"div_table\", \"div_function\"\
}\
local unifiable = setify{\"char\", \"set\", \"range\"}\
local hasCmt; hasCmt = setmetatable({}, {__mode = \"k\", __index = function(self, pt)\
    local kind, res = pt.pkind, false\
    if kind == \"Cmt\"\
    or kind == \"ref\"\
    then\
        res = true\
    elseif unary[kind] or unary_aux[kind] then\
        res = hasCmt[pt.pattern]\
    elseif kind == \"choice\" or kind == \"sequence\" then\
        res = hasCmt[pt[1]] or hasCmt[pt[2]]\
    end\
    hasCmt[pt] = res\
    return res\
end})\
return function (Builder, LL) --------------------------------------------------\
if Builder.options.factorize == false then\
    return {\
        choice = nop,\
        sequence = nop,\
        lookahead = nop,\
        unm = nop\
    }\
end\
local constructors, LL_P =  Builder.constructors, LL.P\
local truept, falsept\
    = constructors.constant.truept\
    , constructors.constant.falsept\
local --Range, Set,\
    S_union\
    = --Builder.Range, Builder.set.new,\
    Builder.set.union\
local mergeable = setify{\"char\", \"set\"}\
local type2cons = {\
    [\"/zero\"] = \"__div\",\
    [\"div_number\"] = \"__div\",\
    [\"div_string\"] = \"__div\",\
    [\"div_table\"] = \"__div\",\
    [\"div_function\"] = \"__div\",\
    [\"at least\"] = \"__exp\",\
    [\"at most\"] = \"__exp\",\
    [\"Clb\"] = \"Cg\",\
}\
local\
function choice (a, b)\
    do  -- handle the identity/break properties of true and false.\
        local hasbool, res = process_booleans(a, b, { id = falsept, brk = truept })\
        if hasbool then return res end\
    end\
    local ka, kb = a.pkind, b.pkind\
    if a == b and not hasCmt[a] then\
        return a\
    elseif ka == \"choice\" then -- correct associativity without blowing up the stack\
        local acc, i = {}, 1\
        while a.pkind == \"choice\" do\
            acc[i], a, i = a[1], a[2], i + 1\
        end\
        acc[i] = a\
        for j = i, 1, -1 do\
            b = acc[j] + b\
        end\
        return b\
    elseif mergeable[ka] and mergeable[kb] then\
        return constructors.aux(\"set\", S_union(a.aux, b.aux))\
    elseif mergeable[ka] and kb == \"any\" and b.aux == 1\
    or     mergeable[kb] and ka == \"any\" and a.aux == 1 then\
        return ka == \"any\" and a or b\
    elseif ka == kb then\
        if (unary[ka] or unary_aux[ka]) and ( a.aux == b.aux ) then\
            return LL[type2cons[ka] or ka](a.pattern + b.pattern, a.aux)\
        elseif ( ka == kb ) and ka == \"sequence\" then\
            if a[1] == b[1]  and not hasCmt[a[1]] then\
                return a[1] * (a[2] + b[2])\
            end\
        end\
    end\
    return false\
end\
local\
function lookahead (pt)\
    return pt\
end\
local\
function sequence(a, b)\
    do\
        local hasbool, res = process_booleans(a, b, { id = truept, brk = falsept })\
        if hasbool then return res end\
    end\
    local ka, kb = a.pkind, b.pkind\
    if ka == \"sequence\" then -- correct associativity without blowing up the stack\
        local acc, i = {}, 1\
        while a.pkind == \"sequence\" do\
            acc[i], a, i = a[1], a[2], i + 1\
        end\
        acc[i] = a\
        for j = i, 1, -1 do\
            b = acc[j] * b\
        end\
        return b\
    elseif (ka == \"one\" or ka == \"any\") and (kb == \"one\" or kb == \"any\") then\
        return LL_P(a.aux + b.aux)\
    end\
    return false\
end\
local\
function unm (pt)\
    if     pt == truept            then return falsept\
    elseif pt == falsept           then return truept\
    elseif pt.pkind == \"unm\"       then return #pt.pattern\
    elseif pt.pkind == \"lookahead\" then return -pt.pattern\
    end\
end\
return {\
    choice = choice,\
    lookahead = lookahead,\
    sequence = sequence,\
    unm = unm\
}\
end\
\
end\
end\
--=============================================================================\
do local _ENV = _ENV\
packages['match'] = function (...)\
\
end\
end\
--=============================================================================\
do local _ENV = _ENV\
packages['util'] = function (...)\
\
local getmetatable, setmetatable, load, loadstring, next\
    , pairs, pcall, print, rawget, rawset, select, tostring\
    , type, unpack\
    = getmetatable, setmetatable, load, loadstring, next\
    , pairs, pcall, print, rawget, rawset, select, tostring\
    , type, unpack\
local m, s, t = require\"math\", require\"string\", require\"table\"\
local m_max, s_match, s_gsub, t_concat, t_insert\
    = m.max, s.match, s.gsub, t.concat, t.insert\
local compat = require\"compat\"\
local\
function nop () end\
local noglobals, getglobal, setglobal if pcall and not compat.lua52 and not release then\
    local function errR (_,i)\
        error(\"illegal global read: \" .. tostring(i), 2)\
    end\
    local function errW (_,i, v)\
        error(\"illegal global write: \" .. tostring(i)..\": \"..tostring(v), 2)\
    end\
    local env = setmetatable({}, { __index=errR, __newindex=errW })\
    noglobals = function()\
        pcall(setfenv, 3, env)\
    end\
    function getglobal(k) rawget(env, k) end\
    function setglobal(k, v) rawset(env, k, v) end\
else\
    noglobals = nop\
end\
local _ENV = noglobals() ------------------------------------------------------\
local util = {\
    nop = nop,\
    noglobals = noglobals,\
    getglobal = getglobal,\
    setglobal = setglobal\
}\
util.unpack = t.unpack or unpack\
util.pack = t.pack or function(...) return { n = select('#', ...), ... } end\
if compat.lua51 then\
    local old_load = load\
   function util.load (ld, source, mode, env)\
     local fun\
     if type (ld) == 'string' then\
       fun = loadstring (ld)\
     else\
       fun = old_load (ld, source)\
     end\
     if env then\
       setfenv (fun, env)\
     end\
     return fun\
   end\
else\
    util.load = load\
end\
if compat.luajit and compat.jit then\
    function util.max (ary)\
        local max = 0\
        for i = 1, #ary do\
            max = m_max(max,ary[i])\
        end\
        return max\
    end\
elseif compat.luajit then\
    local t_unpack = util.unpack\
    function util.max (ary)\
     local len = #ary\
        if len <=30 or len > 10240 then\
            local max = 0\
            for i = 1, #ary do\
                local j = ary[i]\
                if j > max then max = j end\
            end\
            return max\
        else\
            return m_max(t_unpack(ary))\
        end\
    end\
else\
    local t_unpack = util.unpack\
    local safe_len = 1000\
    function util.max(array)\
        local len = #array\
        if len == 0 then return -1 end -- FIXME: shouldn't this be `return -1`?\
        local off = 1\
        local off_end = safe_len\
        local max = array[1] -- seed max.\
        repeat\
            if off_end > len then off_end = len end\
            local seg_max = m_max(t_unpack(array, off, off_end))\
            if seg_max > max then\
                max = seg_max\
            end\
            off = off + safe_len\
            off_end = off_end + safe_len\
        until off >= len\
        return max\
    end\
end\
local\
function setmode(t,mode)\
    local mt = getmetatable(t) or {}\
    if mt.__mode then\
        error(\"The mode has already been set on table \"..tostring(t)..\".\")\
    end\
    mt.__mode = mode\
    return setmetatable(t, mt)\
end\
util.setmode = setmode\
function util.weakboth (t)\
    return setmode(t,\"kv\")\
end\
function util.weakkey (t)\
    return setmode(t,\"k\")\
end\
function util.weakval (t)\
    return setmode(t,\"v\")\
end\
function util.strip_mt (t)\
    return setmetatable(t, nil)\
end\
local getuniqueid\
do\
    local N, index = 0, {}\
    function getuniqueid(v)\
        if not index[v] then\
            N = N + 1\
            index[v] = N\
        end\
        return index[v]\
    end\
end\
util.getuniqueid = getuniqueid\
do\
    local counter = 0\
    function util.gensym ()\
        counter = counter + 1\
        return \"___SYM_\"..counter\
    end\
end\
function util.passprint (...) print(...) return ... end\
local val_to_str_, key_to_str, table_tostring, cdata_to_str, t_cache\
local multiplier = 2\
local\
function val_to_string (v, indent)\
    indent = indent or 0\
    t_cache = {} -- upvalue.\
    local acc = {}\
    val_to_str_(v, acc, indent, indent)\
    local res = t_concat(acc, \"\")\
    return res\
end\
util.val_to_str = val_to_string\
function val_to_str_ ( v, acc, indent, str_indent )\
    str_indent = str_indent or 1\
    if \"string\" == type( v ) then\
        v = s_gsub( v, \"\\n\",  \"\\n\" .. (\" \"):rep( indent * multiplier + str_indent ) )\
        if s_match( s_gsub( v,\"[^'\\\"]\",\"\"), '^\"+$' ) then\
            acc[#acc+1] = t_concat{ \"'\", \"\", v, \"'\" }\
        else\
            acc[#acc+1] = t_concat{'\"', s_gsub(v,'\"', '\\\\\"' ), '\"' }\
        end\
    elseif \"cdata\" == type( v ) then\
            cdata_to_str( v, acc, indent )\
    elseif \"table\" == type(v) then\
        if t_cache[v] then\
            acc[#acc+1] = t_cache[v]\
        else\
            t_cache[v] = tostring( v )\
            table_tostring( v, acc, indent )\
        end\
    else\
        acc[#acc+1] = tostring( v )\
    end\
end\
function key_to_str ( k, acc, indent )\
    if \"string\" == type( k ) and s_match( k, \"^[_%a][_%a%d]*$\" ) then\
        acc[#acc+1] = s_gsub( k, \"\\n\", (\" \"):rep( indent * multiplier + 1 ) .. \"\\n\" )\
    else\
        acc[#acc+1] = \"[ \"\
        val_to_str_( k, acc, indent )\
        acc[#acc+1] = \" ]\"\
    end\
end\
function cdata_to_str(v, acc, indent)\
    acc[#acc+1] = ( \" \" ):rep( indent * multiplier )\
    acc[#acc+1] = \"[\"\
    print(#acc)\
    for i = 0, #v do\
        if i % 16 == 0 and i ~= 0 then\
            acc[#acc+1] = \"\\n\"\
            acc[#acc+1] = (\" \"):rep(indent * multiplier + 2)\
        end\
        acc[#acc+1] = v[i] and 1 or 0\
        acc[#acc+1] = i ~= #v and  \", \" or \"\"\
    end\
    print(#acc, acc[1], acc[2])\
    acc[#acc+1] = \"]\"\
end\
function table_tostring ( tbl, acc, indent )\
    acc[#acc+1] = t_cache[tbl]\
    acc[#acc+1] = \"{\\n\"\
    for k, v in pairs( tbl ) do\
        local str_indent = 1\
        acc[#acc+1] = (\" \"):rep((indent + 1) * multiplier)\
        key_to_str( k, acc, indent + 1)\
        if acc[#acc] == \" ]\"\
        and acc[#acc - 2] == \"[ \"\
        then str_indent = 8 + #acc[#acc - 1]\
        end\
        acc[#acc+1] = \" = \"\
        val_to_str_( v, acc, indent + 1, str_indent)\
        acc[#acc+1] = \"\\n\"\
    end\
    acc[#acc+1] = ( \" \" ):rep( indent * multiplier )\
    acc[#acc+1] = \"}\"\
end\
function util.expose(v) print(val_to_string(v)) return v end\
function util.map (ary, func, ...)\
    if type(ary) == \"function\" then ary, func = func, ary end\
    local res = {}\
    for i = 1,#ary do\
        res[i] = func(ary[i], ...)\
    end\
    return res\
end\
function util.selfmap (ary, func, ...)\
    if type(ary) == \"function\" then ary, func = func, ary end\
    for i = 1,#ary do\
        ary[i] = func(ary[i], ...)\
    end\
    return ary\
end\
local\
function map_all (tbl, func, ...)\
    if type(tbl) == \"function\" then tbl, func = func, tbl end\
    local res = {}\
    for k, v in next, tbl do\
        res[k]=func(v, ...)\
    end\
    return res\
end\
util.map_all = map_all\
local\
function fold (ary, func, acc)\
    local i0 = 1\
    if not acc then\
        acc = ary[1]\
        i0 = 2\
    end\
    for i = i0, #ary do\
        acc = func(acc,ary[i])\
    end\
    return acc\
end\
util.fold = fold\
local\
function foldr (ary, func, acc)\
    local offset = 0\
    if not acc then\
        acc = ary[#ary]\
        offset = 1\
    end\
    for i = #ary - offset, 1 , -1 do\
        acc = func(ary[i], acc)\
    end\
    return acc\
end\
util.foldr = foldr\
local\
function map_fold(ary, mfunc, ffunc, acc)\
    local i0 = 1\
    if not acc then\
        acc = mfunc(ary[1])\
        i0 = 2\
    end\
    for i = i0, #ary do\
        acc = ffunc(acc,mfunc(ary[i]))\
    end\
    return acc\
end\
util.map_fold = map_fold\
local\
function map_foldr(ary, mfunc, ffunc, acc)\
    local offset = 0\
    if not acc then\
        acc = mfunc(ary[#acc])\
        offset = 1\
    end\
    for i = #ary - offset, 1 , -1 do\
        acc = ffunc(mfunc(ary[i], acc))\
    end\
    return acc\
end\
util.map_foldr = map_fold\
function util.zip(a1, a2)\
    local res, len = {}, m_max(#a1,#a2)\
    for i = 1,len do\
        res[i] = {a1[i], a2[i]}\
    end\
    return res\
end\
function util.zip_all(t1, t2)\
    local res = {}\
    for k,v in pairs(t1) do\
        res[k] = {v, t2[k]}\
    end\
    for k,v in pairs(t2) do\
        if res[k] == nil then\
            res[k] = {t1[k], v}\
        end\
    end\
    return res\
end\
function util.filter(ary,func)\
    local res = {}\
    for i = 1,#ary do\
        if func(ary[i]) then\
            t_insert(res, ary[i])\
        end\
    end\
end\
local\
function id (...) return ... end\
util.id = id\
local function AND (a,b) return a and b end\
local function OR  (a,b) return a or b  end\
function util.copy (tbl) return map_all(tbl, id) end\
function util.all (ary, mfunc)\
    if mfunc then\
        return map_fold(ary, mfunc, AND)\
    else\
        return fold(ary, AND)\
    end\
end\
function util.any (ary, mfunc)\
    if mfunc then\
        return map_fold(ary, mfunc, OR)\
    else\
        return fold(ary, OR)\
    end\
end\
function util.get(field)\
    return function(tbl) return tbl[field] end\
end\
function util.lt(ref)\
    return function(val) return val < ref end\
end\
function util.compose(f,g)\
    return function(...) return f(g(...)) end\
end\
function util.extend (destination, ...)\
    for i = 1, select('#', ...) do\
        for k,v in pairs((select(i, ...))) do\
            destination[k] = v\
        end\
    end\
    return destination\
end\
function util.setify (t)\
    local set = {}\
    for i = 1, #t do\
        set[t[i]]=true\
    end\
    return set\
end\
function util.arrayify (...) return {...} end\
local\
function _checkstrhelper(s)\
    return s..\"\"\
end\
function util.checkstring(s, func)\
    local success, str = pcall(_checkstrhelper, s)\
    if not success then \
        if func == nil then func = \"?\" end\
        error(\"bad argument to '\"\
            ..tostring(func)\
            ..\"' (string expected, got \"\
            ..type(s)\
            ..\")\",\
        2)\
    end\
    return str\
end\
return util\
\
end\
end\
--=============================================================================\
do local _ENV = _ENV\
packages['API'] = function (...)\
\
local assert, error, ipairs, pairs, pcall, print\
    , require, select, tonumber, tostring, type\
    = assert, error, ipairs, pairs, pcall, print\
    , require, select, tonumber, tostring, type\
local t, u = require\"table\", require\"util\"\
local _ENV = u.noglobals() ---------------------------------------------------\
local t_concat = t.concat\
local   checkstring,   copy,   fold,   load,   map_fold,   map_foldr,   setify, t_pack, t_unpack\
    = u.checkstring, u.copy, u.fold, u.load, u.map_fold, u.map_foldr, u.setify, u.pack, u.unpack\
local\
function charset_error(index, charset)\
    error(\"Character at position \".. index + 1\
            ..\" is not a valid \"..charset..\" one.\",\
        2)\
end\
return function(Builder, LL) -- module wrapper -------------------------------\
local cs = Builder.charset\
local constructors, LL_ispattern\
    = Builder.constructors, LL.ispattern\
local truept, falsept, Cppt\
    = constructors.constant.truept\
    , constructors.constant.falsept\
    , constructors.constant.Cppt\
local    split_int,    validate\
    = cs.split_int, cs.validate\
local Range, Set, S_union, S_tostring\
    = Builder.Range, Builder.set.new\
    , Builder.set.union, Builder.set.tostring\
local factorize_choice, factorize_lookahead, factorize_sequence, factorize_unm\
local\
function makechar(c)\
    return constructors.aux(\"char\", c)\
end\
local\
function LL_P (...)\
    local v, n = (...), select('#', ...)\
    if n == 0 then error\"bad argument #1 to 'P' (value expected)\" end\
    local typ = type(v)\
    if LL_ispattern(v) then\
        return v\
    elseif typ == \"function\" then\
        return \
            LL.Cmt(\"\", v)\
    elseif typ == \"string\" then\
        local success, index = validate(v)\
        if not success then\
            charset_error(index, cs.name)\
        end\
        if v == \"\" then return truept end\
        return \
            map_foldr(split_int(v), makechar, Builder.sequence)\
    elseif typ == \"table\" then\
        local g = copy(v)\
        if g[1] == nil then error(\"grammar has no initial rule\") end\
        if not LL_ispattern(g[1]) then g[1] = LL.V(g[1]) end\
        return\
            constructors.none(\"grammar\", g)\
    elseif typ == \"boolean\" then\
        return v and truept or falsept\
    elseif typ == \"number\" then\
        if v == 0 then\
            return truept\
        elseif v > 0 then\
            return\
                constructors.aux(\"any\", v)\
        else\
            return\
                - constructors.aux(\"any\", -v)\
        end\
    else\
        error(\"bad argument #1 to 'P' (lpeg-pattern expected, got \"..typ..\")\")\
    end\
end\
LL.P = LL_P\
local\
function LL_S (set)\
    if set == \"\" then\
        return\
            falsept\
    else\
        local success\
        set = checkstring(set, \"S\")\
        return\
            constructors.aux(\"set\", Set(split_int(set)), set)\
    end\
end\
LL.S = LL_S\
local\
function LL_R (...)\
    if select('#', ...) == 0 then\
        return LL_P(false)\
    else\
        local range = Range(1,0)--Set(\"\")\
        for _, r in ipairs{...} do\
            r = checkstring(r, \"R\")\
            assert(#r == 2, \"bad argument #1 to 'R' (range must have two characters)\")\
            range = S_union ( range, Range(t_unpack(split_int(r))) )\
        end\
        return\
            constructors.aux(\"set\", range)\
    end\
end\
LL.R = LL_R\
local\
function LL_V (name)\
    assert(name ~= nil)\
    return\
        constructors.aux(\"ref\",  name)\
end\
LL.V = LL_V\
do\
    local one = setify{\"set\", \"range\", \"one\", \"char\"}\
    local zero = setify{\"true\", \"false\", \"lookahead\", \"unm\"}\
    local forbidden = setify{\
        \"Carg\", \"Cb\", \"C\", \"Cf\",\
        \"Cg\", \"Cs\", \"Ct\", \"/zero\",\
        \"Clb\", \"Cmt\", \"Cc\", \"Cp\",\
        \"div_string\", \"div_number\", \"div_table\", \"div_function\",\
        \"at least\", \"at most\", \"behind\"\
    }\
    local function fixedlen(pt, gram, cycle)\
        local typ = pt.pkind\
        if forbidden[typ] then return false\
        elseif one[typ]  then return 1\
        elseif zero[typ] then return 0\
        elseif typ == \"string\" then return #pt.as_is\
        elseif typ == \"any\" then return pt.aux\
        elseif typ == \"choice\" then\
            local l1, l2 = fixedlen(pt[1], gram, cycle), fixedlen(pt[2], gram, cycle)\
            return (l1 == l2) and l1\
        elseif typ == \"sequence\" then\
            local l1, l2 = fixedlen(pt[1], gram, cycle), fixedlen(pt[2], gram, cycle)\
            return l1 and l2 and l1 + l2\
        elseif typ == \"grammar\" then\
            if pt.aux[1].pkind == \"ref\" then\
                return fixedlen(pt.aux[pt.aux[1].aux], pt.aux, {})\
            else\
                return fixedlen(pt.aux[1], pt.aux, {})\
            end\
        elseif typ == \"ref\" then\
            if cycle[pt] then return false end\
            cycle[pt] = true\
            return fixedlen(gram[pt.aux], gram, cycle)\
        else\
            print(typ,\"is not handled by fixedlen()\")\
        end\
    end\
    function LL.B (pt)\
        pt = LL_P(pt)\
        local len = fixedlen(pt)\
        assert(len, \"A 'behind' pattern takes a fixed length pattern as argument.\")\
        if len >= 260 then error(\"Subpattern too long in 'behind' pattern constructor.\") end\
        return\
            constructors.both(\"behind\", pt, len)\
    end\
end\
local function nameify(a, b)\
    return tostring(a)..tostring(b)\
end\
local\
function choice (a, b)\
    local name = tostring(a)..tostring(b)\
    local ch = Builder.ptcache.choice[name]\
    if not ch then\
        ch = factorize_choice(a, b) or constructors.binary(\"choice\", a, b)\
        Builder.ptcache.choice[name] = ch\
    end\
    return ch\
end\
function LL.__add (a, b)\
    return \
        choice(LL_P(a), LL_P(b))\
end\
local\
function sequence (a, b)\
    local name = tostring(a)..tostring(b)\
    local seq = Builder.ptcache.sequence[name]\
    if not seq then\
        seq = factorize_sequence(a, b) or constructors.binary(\"sequence\", a, b)\
        Builder.ptcache.sequence[name] = seq\
    end\
    return seq\
end\
Builder.sequence = sequence\
function LL.__mul (a, b)\
    return \
        sequence(LL_P(a), LL_P(b))\
end\
local\
function LL_lookahead (pt)\
    if pt == truept\
    or pt == falsept\
    or pt.pkind == \"unm\"\
    or pt.pkind == \"lookahead\"\
    then\
        return pt\
    end\
    return\
        constructors.subpt(\"lookahead\", pt)\
end\
LL.__len = LL_lookahead\
LL.L = LL_lookahead\
local\
function LL_unm(pt)\
    return\
        factorize_unm(pt)\
        or constructors.subpt(\"unm\", pt)\
end\
LL.__unm = LL_unm\
local\
function LL_sub (a, b)\
    a, b = LL_P(a), LL_P(b)\
    return LL_unm(b) * a\
end\
LL.__sub = LL_sub\
local\
function LL_repeat (pt, n)\
    local success\
    success, n = pcall(tonumber, n)\
    assert(success and type(n) == \"number\",\
        \"Invalid type encountered at right side of '^'.\")\
    return constructors.both(( n < 0 and \"at most\" or \"at least\" ), pt, n)\
end\
LL.__pow = LL_repeat\
for _, cap in pairs{\"C\", \"Cs\", \"Ct\"} do\
    LL[cap] = function(pt)\
        pt = LL_P(pt)\
        return\
            constructors.subpt(cap, pt)\
    end\
end\
LL[\"Cb\"] = function(aux)\
    return\
        constructors.aux(\"Cb\", aux)\
end\
LL[\"Carg\"] = function(aux)\
    assert(type(aux)==\"number\", \"Number expected as parameter to Carg capture.\")\
    assert( 0 < aux and aux <= 200, \"Argument out of bounds in Carg capture.\")\
    return\
        constructors.aux(\"Carg\", aux)\
end\
local\
function LL_Cp ()\
    return Cppt\
end\
LL.Cp = LL_Cp\
local\
function LL_Cc (...)\
    return\
        constructors.none(\"Cc\", t_pack(...))\
end\
LL.Cc = LL_Cc\
for _, cap in pairs{\"Cf\", \"Cmt\"} do\
    local msg = \"Function expected in \"..cap..\" capture\"\
    LL[cap] = function(pt, aux)\
    assert(type(aux) == \"function\", msg)\
    pt = LL_P(pt)\
    return\
        constructors.both(cap, pt, aux)\
    end\
end\
local\
function LL_Cg (pt, tag)\
    pt = LL_P(pt)\
    if tag ~= nil then\
        return\
            constructors.both(\"Clb\", pt, tag)\
    else\
        return\
            constructors.subpt(\"Cg\", pt)\
    end\
end\
LL.Cg = LL_Cg\
local valid_slash_type = setify{\"string\", \"number\", \"table\", \"function\"}\
local\
function LL_slash (pt, aux)\
    if LL_ispattern(aux) then\
        error\"The right side of a '/' capture cannot be a pattern.\"\
    elseif not valid_slash_type[type(aux)] then\
        error(\"The right side of a '/' capture must be of type \"\
            ..\"string, number, table or function.\")\
    end\
    local name\
    if aux == 0 then\
        name = \"/zero\"\
    else\
        name = \"div_\"..type(aux)\
    end\
    return\
        constructors.both(name, pt, aux)\
end\
LL.__div = LL_slash\
if Builder.proxymt then\
    for k, v in pairs(LL) do\
        if k:match\"^__\" then\
            Builder.proxymt[k] = v\
        end\
    end\
else\
    LL.__index = LL\
end\
local factorizer\
    = Builder.factorizer(Builder, LL)\
factorize_choice,  factorize_lookahead,  factorize_sequence,  factorize_unm =\
factorizer.choice, factorizer.lookahead, factorizer.sequence, factorizer.unm\
end -- module wrapper --------------------------------------------------------\
\
end\
end\
--=============================================================================\
do local _ENV = _ENV\
packages['constructors'] = function (...)\
\
local getmetatable, ipairs, newproxy, print, setmetatable\
    = getmetatable, ipairs, newproxy, print, setmetatable\
local t, u, compat\
    = require\"table\", require\"util\", require\"compat\"\
local t_concat = t.concat\
local   copy,   getuniqueid,   id,   map\
    ,   weakkey,   weakval\
    = u.copy, u.getuniqueid, u.id, u.map\
    , u.weakkey, u.weakval\
local _ENV = u.noglobals() ----------------------------------------------------\
local patternwith = {\
    constant = {\
        \"Cp\", \"true\", \"false\"\
    },\
    aux = {\
        \"string\", \"any\",\
        \"char\", \"range\", \"set\",\
        \"ref\", \"sequence\", \"choice\",\
        \"Carg\", \"Cb\"\
    },\
    subpt = {\
        \"unm\", \"lookahead\", \"C\", \"Cf\",\
        \"Cg\", \"Cs\", \"Ct\", \"/zero\"\
    },\
    both = {\
        \"behind\", \"at least\", \"at most\", \"Clb\", \"Cmt\",\
        \"div_string\", \"div_number\", \"div_table\", \"div_function\"\
    },\
    none = \"grammar\", \"Cc\"\
}\
return function(Builder, LL) --- module wrapper.\
local S_tostring = Builder.set.tostring\
local newpattern, pattmt\
if compat.proxies and not compat.lua52_len then \
    local proxycache = weakkey{}\
    local __index_LL = {__index = LL}\
    local baseproxy = newproxy(true)\
    pattmt = getmetatable(baseproxy)\
    Builder.proxymt = pattmt\
    function pattmt:__index(k)\
        return proxycache[self][k]\
    end\
    function pattmt:__newindex(k, v)\
        proxycache[self][k] = v\
    end\
    function LL.getdirect(p) return proxycache[p] end\
    function newpattern(cons)\
        local pt = newproxy(baseproxy)\
        setmetatable(cons, __index_LL)\
        proxycache[pt]=cons\
        return pt\
    end\
else\
    if LL.warnings and not compat.lua52_len then\
        print(\"Warning: The `__len` metatethod won't work with patterns, \"\
            ..\"use `LL.L(pattern)` for lookaheads.\")\
    end\
    pattmt = LL\
    function LL.getdirect (p) return p end\
    function newpattern(pt)\
        return setmetatable(pt,LL)\
    end\
end\
Builder.newpattern = newpattern\
local\
function LL_ispattern(pt) return getmetatable(pt) == pattmt end\
LL.ispattern = LL_ispattern\
function LL.type(pt)\
    if LL_ispattern(pt) then\
        return \"pattern\"\
    else\
        return nil\
    end\
end\
local ptcache, meta\
local\
function resetcache()\
    ptcache, meta = {}, weakkey{}\
    Builder.ptcache = ptcache\
    for _, p in ipairs(patternwith.aux) do\
        ptcache[p] = weakval{}\
    end\
    for _, p in ipairs(patternwith.subpt) do\
        ptcache[p] = weakval{}\
    end\
    for _, p in ipairs(patternwith.both) do\
        ptcache[p] = {}\
    end\
    return ptcache\
end\
LL.resetptcache = resetcache\
resetcache()\
local constructors = {}\
Builder.constructors = constructors\
constructors[\"constant\"] = {\
    truept  = newpattern{ pkind = \"true\" },\
    falsept = newpattern{ pkind = \"false\" },\
    Cppt    = newpattern{ pkind = \"Cp\" }\
}\
local getauxkey = {\
    string = function(aux, as_is) return as_is end,\
    table = copy,\
    set = function(aux, as_is)\
        return S_tostring(aux)\
    end,\
    range = function(aux, as_is)\
        return t_concat(as_is, \"|\")\
    end,\
    sequence = function(aux, as_is)\
        return t_concat(map(getuniqueid, aux),\"|\")\
    end\
}\
getauxkey.choice = getauxkey.sequence\
constructors[\"aux\"] = function(typ, aux, as_is)\
    local cache = ptcache[typ]\
    local key = (getauxkey[typ] or id)(aux, as_is)\
    if not cache[key] then\
        cache[key] = newpattern{\
            pkind = typ,\
            aux = aux,\
            as_is = as_is\
        }\
    end\
    return cache[key]\
end\
constructors[\"none\"] = function(typ, aux)\
    return newpattern{\
        pkind = typ,\
        aux = aux\
    }\
end\
constructors[\"subpt\"] = function(typ, pt)\
    local cache = ptcache[typ]\
    if not cache[pt] then\
        cache[pt] = newpattern{\
            pkind = typ,\
            pattern = pt\
        }\
    end\
    return cache[pt]\
end\
constructors[\"both\"] = function(typ, pt, aux)\
    local cache = ptcache[typ][aux]\
    if not cache then\
        ptcache[typ][aux] = weakval{}\
        cache = ptcache[typ][aux]\
    end\
    if not cache[pt] then\
        cache[pt] = newpattern{\
            pkind = typ,\
            pattern = pt,\
            aux = aux,\
            cache = cache -- needed to keep the cache as long as the pattern exists.\
        }\
    end\
    return cache[pt]\
end\
constructors[\"binary\"] = function(typ, a, b)\
    return newpattern{\
        a, b;\
        pkind = typ,\
    }\
end\
end -- module wrapper\
\
end\
end\
--=============================================================================\
do local _ENV = _ENV\
packages['init'] = function (...)\
\
local getmetatable, setmetatable, pcall\
    = getmetatable, setmetatable, pcall\
local u = require\"util\"\
local   copy,   map,   nop, t_unpack\
    = u.copy, u.map, u.nop, u.unpack\
local API, charsets, compiler, constructors\
    , datastructures, evaluator, factorizer\
    , locale, printers, re\
    = t_unpack(map(require,\
    { \"API\", \"charsets\", \"compiler\", \"constructors\"\
    , \"datastructures\", \"evaluator\", \"factorizer\"\
    , \"locale\", \"printers\", \"re\" }))\
local _, package = pcall(require, \"package\")\
local _ENV = u.noglobals() ----------------------------------------------------\
local VERSION = \"0.12\"\
local LuVERSION = \"0.1.0\"\
local function global(self, env) setmetatable(env,{__index = self}) end\
local function register(self, env)\
    pcall(function()\
        package.loaded.lpeg = self\
        package.loaded.re = self.re\
    end)\
    if env then\
        env.lpeg, env.re = self, self.re\
    end\
    return self\
end\
local\
function LuLPeg(options)\
    options = options and copy(options) or {}\
    local Builder, LL\
        = { options = options, factorizer = factorizer }\
        , { new = LuLPeg\
          , version = function () return VERSION end\
          , luversion = function () return LuVERSION end\
          , setmaxstack = nop --Just a stub, for compatibility.\
          }\
    LL.util = u\
    LL.global = global\
    LL.register = register\
    ;-- Decorate the LuLPeg object.\
    charsets(Builder, LL)\
    datastructures(Builder, LL)\
    printers(Builder, LL)\
    constructors(Builder, LL)\
    API(Builder, LL)\
    evaluator(Builder, LL)\
    ;(options.compiler or compiler)(Builder, LL)\
    locale(Builder, LL)\
    LL.re = re(Builder, LL)\
    return LL\
end -- LuLPeg\
local LL = LuLPeg()\
return LL\
\
end\
end\
--=============================================================================\
do local _ENV = _ENV\
packages['locale'] = function (...)\
\
local extend = require\"util\".extend\
local _ENV = require\"util\".noglobals() ----------------------------------------\
return function(Builder, LL) -- Module wrapper {-------------------------------\
local R, S = LL.R, LL.S\
local locale = {}\
locale[\"cntrl\"] = R\"\\0\\31\" + \"\\127\"\
locale[\"digit\"] = R\"09\"\
locale[\"lower\"] = R\"az\"\
locale[\"print\"] = R\" ~\" -- 0x20 to 0xee\
locale[\"space\"] = S\" \\f\\n\\r\\t\\v\" -- \\f == form feed (for a printer), \\v == vtab\
locale[\"upper\"] = R\"AZ\"\
locale[\"alpha\"]  = locale[\"lower\"] + locale[\"upper\"]\
locale[\"alnum\"]  = locale[\"alpha\"] + locale[\"digit\"]\
locale[\"graph\"]  = locale[\"print\"] - locale[\"space\"]\
locale[\"punct\"]  = locale[\"graph\"] - locale[\"alnum\"]\
locale[\"xdigit\"] = locale[\"digit\"] + R\"af\" + R\"AF\"\
function LL.locale (t)\
    return extend(t or {}, locale)\
end\
end -- Module wrapper --------------------------------------------------------}\
\
end\
end\
--=============================================================================\
do local _ENV = _ENV\
packages['optimizer'] = function (...)\
-- Nothing for now.\
end\
end\
return require\"init\"\
\
\
\
--                   The Romantic WTF public license.\
--                   --------------------------------\
--                   a.k.a. version \"<3\" or simply v3\
-- \
-- \
--            Dear user,\
-- \
--            The LuLPeg library\
-- \
--                                             \\ \
--                                              '.,__\
--                                           \\  /\
--                                            '/,__\
--                                            /\
--                                           /\
--                                          /\
--                       has been          / released\
--                  ~ ~ ~ ~ ~ ~ ~ ~       ~ ~ ~ ~ ~ ~ ~ ~ \
--                under  the  Romantic   WTF Public License.\
--               ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~`,´ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ \
--               I hereby grant you an irrevocable license to\
--                ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~\
--                  do what the gentle caress you want to\
--                       ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~  \
--                           with   this   lovely\
--                              ~ ~ ~ ~ ~ ~ ~ ~ \
--                               / library...\
--                              /  ~ ~ ~ ~\
--                             /    Love,\
--                        #   /      ','\
--                        #######    ·\
--                        #####\
--                        ###\
--                        #\
-- \
--               -- Pierre-Yves\
-- \
-- \
-- \
--            P.S.: Even though I poured my heart into this work, \
--                  I _cannot_ provide any warranty regarding \
--                  its fitness for _any_ purpose. You\
--                  acknowledge that I will not be held liable\
--                  for any damage its use could incur.\
-- \
-- -----------------------------------------------------------------------------            \
-- \
-- LuLPeg, Copyright (C) 2013 Pierre-Yves Gérardy.\
-- \
-- The `re` module and lpeg.*.*.test.lua,\
-- Copyright (C) 2013 Lua.org, PUC-Rio.\
-- \
-- Permission is hereby granted, free of charge,\
-- to any person obtaining a copy of this software and\
-- associated documentation files (the \"Software\"),\
-- to deal in the Software without restriction,\
-- including without limitation the rights to use,\
-- copy, modify, merge, publish, distribute, sublicense,\
-- and/or sell copies of the Software,\
-- and to permit persons to whom the Software is\
-- furnished to do so,\
-- subject to the following conditions:\
-- \
-- The above copyright notice and this permission notice\
-- shall be included in all copies or substantial portions of the Software.\
-- \
-- THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND,\
-- EXPRESS OR IMPLIED,\
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.\
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,\
-- DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,\
-- TORT OR OTHERWISE, ARISING FROM,\
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN\
-- THE SOFTWARE.\
\
"
, '@'.."/usr/share/lua/5.3/lulpeg.lua" ) )

package.loaded.lpeg = require("lulpeg")

package.preload[ "moonscript.parse.literals" ] = assert( (loadstring or load)(
"local safe_module\
safe_module = require(\"moonscript.util\").safe_module\
local S, P, R, C\
do\
  local _obj_0 = require(\"lpeg\")\
  S, P, R, C = _obj_0.S, _obj_0.P, _obj_0.R, _obj_0.C\
end\
local lpeg = require(\"lpeg\")\
local L = lpeg.luversion and lpeg.L or function(v)\
  return #v\
end\
local White = S(\" \\t\\r\\n\") ^ 0\
local plain_space = S(\" \\t\") ^ 0\
local Break = P(\"\\r\") ^ -1 * P(\"\\n\")\
local Stop = Break + -1\
local Comment = P(\"--\") * (1 - S(\"\\r\\n\")) ^ 0 * L(Stop)\
local Space = plain_space * Comment ^ -1\
local SomeSpace = S(\" \\t\") ^ 1 * Comment ^ -1\
local SpaceBreak = Space * Break\
local EmptyLine = SpaceBreak\
local AlphaNum = R(\"az\", \"AZ\", \"09\", \"__\")\
local Name = C(R(\"az\", \"AZ\", \"__\") * AlphaNum ^ 0)\
local Num = P(\"0x\") * R(\"09\", \"af\", \"AF\") ^ 1 * (S(\"uU\") ^ -1 * S(\"lL\") ^ 2) ^ -1 + R(\"09\") ^ 1 * (S(\"uU\") ^ -1 * S(\"lL\") ^ 2) + (R(\"09\") ^ 1 * (P(\".\") * R(\"09\") ^ 1) ^ -1 + P(\".\") * R(\"09\") ^ 1) * (S(\"eE\") * P(\"-\") ^ -1 * R(\"09\") ^ 1) ^ -1\
local Shebang = P(\"#!\") * P(1 - Stop) ^ 0\
return safe_module(\"moonscript.parse.literals\", {\
  L = L,\
  White = White,\
  Break = Break,\
  Stop = Stop,\
  Comment = Comment,\
  Space = Space,\
  SomeSpace = SomeSpace,\
  SpaceBreak = SpaceBreak,\
  EmptyLine = EmptyLine,\
  AlphaNum = AlphaNum,\
  Name = Name,\
  Num = Num,\
  Shebang = Shebang\
})\
"
, '@'.."/usr/share/lua/5.3/moonscript/parse/literals.lua" ) )

package.preload[ "moonscript" ] = assert( (loadstring or load)(
"do\
  local _with_0 = require(\"moonscript.base\")\
  _with_0.insert_loader()\
  return _with_0\
end\
"
, '@'.."/usr/share/lua/5.3/moonscript/init.lua" ) )

package.preload[ "moonscript.transform.transformer" ] = assert( (loadstring or load)(
"local ntype\
ntype = require(\"moonscript.types\").ntype\
local Transformer\
do\
  local _class_0\
  local _base_0 = {\
    transform_once = function(self, scope, node, ...)\
      if self.seen_nodes[node] then\
        return node\
      end\
      self.seen_nodes[node] = true\
      local transformer = self.transformers[ntype(node)]\
      if transformer then\
        return transformer(scope, node, ...) or node\
      else\
        return node\
      end\
    end,\
    transform = function(self, scope, node, ...)\
      if self.seen_nodes[node] then\
        return node\
      end\
      self.seen_nodes[node] = true\
      while true do\
        local transformer = self.transformers[ntype(node)]\
        local res\
        if transformer then\
          res = transformer(scope, node, ...) or node\
        else\
          res = node\
        end\
        if res == node then\
          return node\
        end\
        node = res\
      end\
      return node\
    end,\
    bind = function(self, scope)\
      return function(...)\
        return self:transform(scope, ...)\
      end\
    end,\
    __call = function(self, ...)\
      return self:transform(...)\
    end,\
    can_transform = function(self, node)\
      return self.transformers[ntype(node)] ~= nil\
    end\
  }\
  _base_0.__index = _base_0\
  _class_0 = setmetatable({\
    __init = function(self, transformers)\
      self.transformers = transformers\
      self.seen_nodes = setmetatable({ }, {\
        __mode = \"k\"\
      })\
    end,\
    __base = _base_0,\
    __name = \"Transformer\"\
  }, {\
    __index = _base_0,\
    __call = function(cls, ...)\
      local _self_0 = setmetatable({}, _base_0)\
      cls.__init(_self_0, ...)\
      return _self_0\
    end\
  })\
  _base_0.__class = _class_0\
  Transformer = _class_0\
end\
return {\
  Transformer = Transformer\
}\
"
, '@'.."/usr/share/lua/5.3/moonscript/transform/transformer.lua" ) )

package.preload[ "moonscript.line_tables" ] = assert( (loadstring or load)(
"return { }\
"
, '@'.."/usr/share/lua/5.3/moonscript/line_tables.lua" ) )

package.preload[ "moonscript.util" ] = assert( (loadstring or load)(
"local concat\
concat = table.concat\
local unpack = unpack or table.unpack\
local type = type\
local moon = {\
  is_object = function(value)\
    return type(value) == \"table\" and value.__class\
  end,\
  is_a = function(thing, t)\
    if not (type(thing) == \"table\") then\
      return false\
    end\
    local cls = thing.__class\
    while cls do\
      if cls == t then\
        return true\
      end\
      cls = cls.__parent\
    end\
    return false\
  end,\
  type = function(value)\
    local base_type = type(value)\
    if base_type == \"table\" then\
      local cls = value.__class\
      if cls then\
        return cls\
      end\
    end\
    return base_type\
  end\
}\
local pos_to_line\
pos_to_line = function(str, pos)\
  local line = 1\
  for _ in str:sub(1, pos):gmatch(\"\\n\") do\
    line = line + 1\
  end\
  return line\
end\
local trim\
trim = function(str)\
  return str:match(\"^%s*(.-)%s*$\")\
end\
local get_line\
get_line = function(str, line_num)\
  for line in str:gmatch(\"([^\\n]*)\\n?\") do\
    if line_num == 1 then\
      return line\
    end\
    line_num = line_num - 1\
  end\
end\
local get_closest_line\
get_closest_line = function(str, line_num)\
  local line = get_line(str, line_num)\
  if (not line or trim(line) == \"\") and line_num > 1 then\
    return get_closest_line(str, line_num - 1)\
  else\
    return line, line_num\
  end\
end\
local split\
split = function(str, delim)\
  if str == \"\" then\
    return { }\
  end\
  str = str .. delim\
  local _accum_0 = { }\
  local _len_0 = 1\
  for m in str:gmatch(\"(.-)\" .. delim) do\
    _accum_0[_len_0] = m\
    _len_0 = _len_0 + 1\
  end\
  return _accum_0\
end\
local dump\
dump = function(what)\
  local seen = { }\
  local _dump\
  _dump = function(what, depth)\
    if depth == nil then\
      depth = 0\
    end\
    local t = type(what)\
    if t == \"string\" then\
      return '\"' .. what .. '\"\\n'\
    elseif t == \"table\" then\
      if seen[what] then\
        return \"recursion(\" .. tostring(what) .. \")...\\n\"\
      end\
      seen[what] = true\
      depth = depth + 1\
      local lines\
      do\
        local _accum_0 = { }\
        local _len_0 = 1\
        for k, v in pairs(what) do\
          _accum_0[_len_0] = (\" \"):rep(depth * 4) .. \"[\" .. tostring(k) .. \"] = \" .. _dump(v, depth)\
          _len_0 = _len_0 + 1\
        end\
        lines = _accum_0\
      end\
      seen[what] = false\
      return \"{\\n\" .. concat(lines) .. (\" \"):rep((depth - 1) * 4) .. \"}\\n\"\
    else\
      return tostring(what) .. \"\\n\"\
    end\
  end\
  return _dump(what)\
end\
local debug_posmap\
debug_posmap = function(posmap, moon_code, lua_code)\
  local tuples\
  do\
    local _accum_0 = { }\
    local _len_0 = 1\
    for k, v in pairs(posmap) do\
      _accum_0[_len_0] = {\
        k,\
        v\
      }\
      _len_0 = _len_0 + 1\
    end\
    tuples = _accum_0\
  end\
  table.sort(tuples, function(a, b)\
    return a[1] < b[1]\
  end)\
  local lines\
  do\
    local _accum_0 = { }\
    local _len_0 = 1\
    for _index_0 = 1, #tuples do\
      local pair = tuples[_index_0]\
      local lua_line, pos = unpack(pair)\
      local moon_line = pos_to_line(moon_code, pos)\
      local lua_text = get_line(lua_code, lua_line)\
      local moon_text = get_closest_line(moon_code, moon_line)\
      local _value_0 = tostring(pos) .. \"\\t \" .. tostring(lua_line) .. \":[ \" .. tostring(trim(lua_text)) .. \" ] >> \" .. tostring(moon_line) .. \":[ \" .. tostring(trim(moon_text)) .. \" ]\"\
      _accum_0[_len_0] = _value_0\
      _len_0 = _len_0 + 1\
    end\
    lines = _accum_0\
  end\
  return concat(lines, \"\\n\")\
end\
local setfenv = setfenv or function(fn, env)\
  local name\
  local i = 1\
  while true do\
    name = debug.getupvalue(fn, i)\
    if not name or name == \"_ENV\" then\
      break\
    end\
    i = i + 1\
  end\
  if name then\
    debug.upvaluejoin(fn, i, (function()\
      return env\
    end), 1)\
  end\
  return fn\
end\
local getfenv = getfenv or function(fn)\
  local i = 1\
  while true do\
    local name, val = debug.getupvalue(fn, i)\
    if not (name) then\
      break\
    end\
    if name == \"_ENV\" then\
      return val\
    end\
    i = i + 1\
  end\
  return nil\
end\
local get_options\
get_options = function(...)\
  local count = select(\"#\", ...)\
  local opts = select(count, ...)\
  if type(opts) == \"table\" then\
    return opts, unpack({\
      ...\
    }, nil, count - 1)\
  else\
    return { }, ...\
  end\
end\
local safe_module\
safe_module = function(name, tbl)\
  return setmetatable(tbl, {\
    __index = function(self, key)\
      return error(\"Attempted to import non-existent `\" .. tostring(key) .. \"` from \" .. tostring(name))\
    end\
  })\
end\
return {\
  moon = moon,\
  pos_to_line = pos_to_line,\
  get_closest_line = get_closest_line,\
  get_line = get_line,\
  trim = trim,\
  split = split,\
  dump = dump,\
  debug_posmap = debug_posmap,\
  getfenv = getfenv,\
  setfenv = setfenv,\
  get_options = get_options,\
  unpack = unpack,\
  safe_module = safe_module\
}\
"
, '@'.."/usr/share/lua/5.3/moonscript/util.lua" ) )

package.preload[ "moonscript.transform.names" ] = assert( (loadstring or load)(
"local build\
build = require(\"moonscript.types\").build\
local unpack\
unpack = require(\"moonscript.util\").unpack\
local LocalName\
do\
  local _class_0\
  local _base_0 = {\
    get_name = function(self)\
      return self.name\
    end\
  }\
  _base_0.__index = _base_0\
  _class_0 = setmetatable({\
    __init = function(self, name)\
      self.name = name\
      self[1] = \"temp_name\"\
    end,\
    __base = _base_0,\
    __name = \"LocalName\"\
  }, {\
    __index = _base_0,\
    __call = function(cls, ...)\
      local _self_0 = setmetatable({}, _base_0)\
      cls.__init(_self_0, ...)\
      return _self_0\
    end\
  })\
  _base_0.__class = _class_0\
  LocalName = _class_0\
end\
local NameProxy\
do\
  local _class_0\
  local _base_0 = {\
    get_name = function(self, scope, dont_put)\
      if dont_put == nil then\
        dont_put = true\
      end\
      if not self.name then\
        self.name = scope:free_name(self.prefix, dont_put)\
      end\
      return self.name\
    end,\
    chain = function(self, ...)\
      local items = {\
        base = self,\
        ...\
      }\
      for k, v in ipairs(items) do\
        if type(v) == \"string\" then\
          items[k] = {\
            \"dot\",\
            v\
          }\
        else\
          items[k] = v\
        end\
      end\
      return build.chain(items)\
    end,\
    index = function(self, key)\
      if type(key) == \"string\" then\
        key = {\
          \"ref\",\
          key\
        }\
      end\
      return build.chain({\
        base = self,\
        {\
          \"index\",\
          key\
        }\
      })\
    end,\
    __tostring = function(self)\
      if self.name then\
        return (\"name<%s>\"):format(self.name)\
      else\
        return (\"name<prefix(%s)>\"):format(self.prefix)\
      end\
    end\
  }\
  _base_0.__index = _base_0\
  _class_0 = setmetatable({\
    __init = function(self, prefix)\
      self.prefix = prefix\
      self[1] = \"temp_name\"\
    end,\
    __base = _base_0,\
    __name = \"NameProxy\"\
  }, {\
    __index = _base_0,\
    __call = function(cls, ...)\
      local _self_0 = setmetatable({}, _base_0)\
      cls.__init(_self_0, ...)\
      return _self_0\
    end\
  })\
  _base_0.__class = _class_0\
  NameProxy = _class_0\
end\
local is_name_proxy\
is_name_proxy = function(v)\
  if not (type(v) == \"table\") then\
    return false\
  end\
  local _exp_0 = v.__class\
  if LocalName == _exp_0 or NameProxy == _exp_0 then\
    return true\
  end\
end\
return {\
  NameProxy = NameProxy,\
  LocalName = LocalName,\
  is_name_proxy = is_name_proxy\
}\
"
, '@'.."/usr/share/lua/5.3/moonscript/transform/names.lua" ) )

package.preload[ "moonscript.compile.value" ] = assert( (loadstring or load)(
"local util = require(\"moonscript.util\")\
local data = require(\"moonscript.data\")\
local ntype\
ntype = require(\"moonscript.types\").ntype\
local user_error\
user_error = require(\"moonscript.errors\").user_error\
local concat, insert\
do\
  local _obj_0 = table\
  concat, insert = _obj_0.concat, _obj_0.insert\
end\
local unpack\
unpack = util.unpack\
local table_delim = \",\"\
local string_chars = {\
  [\"\\r\"] = \"\\\\r\",\
  [\"\\n\"] = \"\\\\n\"\
}\
return {\
  scoped = function(self, node)\
    local _, before, value, after\
    _, before, value, after = node[1], node[2], node[3], node[4]\
    _ = before and before:call(self)\
    do\
      local _with_0 = self:value(value)\
      _ = after and after:call(self)\
      return _with_0\
    end\
  end,\
  exp = function(self, node)\
    local _comp\
    _comp = function(i, value)\
      if i % 2 == 1 and value == \"!=\" then\
        value = \"~=\"\
      end\
      return self:value(value)\
    end\
    do\
      local _with_0 = self:line()\
      _with_0:append_list((function()\
        local _accum_0 = { }\
        local _len_0 = 1\
        for i, v in ipairs(node) do\
          if i > 1 then\
            _accum_0[_len_0] = _comp(i, v)\
            _len_0 = _len_0 + 1\
          end\
        end\
        return _accum_0\
      end)(), \" \")\
      return _with_0\
    end\
  end,\
  explist = function(self, node)\
    do\
      local _with_0 = self:line()\
      _with_0:append_list((function()\
        local _accum_0 = { }\
        local _len_0 = 1\
        for _index_0 = 2, #node do\
          local v = node[_index_0]\
          _accum_0[_len_0] = self:value(v)\
          _len_0 = _len_0 + 1\
        end\
        return _accum_0\
      end)(), \", \")\
      return _with_0\
    end\
  end,\
  parens = function(self, node)\
    return self:line(\"(\", self:value(node[2]), \")\")\
  end,\
  string = function(self, node)\
    local delim, inner = unpack(node, 2)\
    local end_delim = delim:gsub(\"%[\", \"]\")\
    if delim == \"'\" or delim == '\"' then\
      inner = inner:gsub(\"[\\r\\n]\", string_chars)\
    end\
    return delim .. inner .. end_delim\
  end,\
  chain = function(self, node)\
    local callee = node[2]\
    local callee_type = ntype(callee)\
    local item_offset = 3\
    if callee_type == \"dot\" or callee_type == \"colon\" or callee_type == \"index\" then\
      callee = self:get(\"scope_var\")\
      if not (callee) then\
        user_error(\"Short-dot syntax must be called within a with block\")\
      end\
      item_offset = 2\
    end\
    if callee_type == \"ref\" and callee[2] == \"super\" or callee == \"super\" then\
      do\
        local sup = self:get(\"super\")\
        if sup then\
          return self:value(sup(self, node))\
        end\
      end\
    end\
    local chain_item\
    chain_item = function(node)\
      local t, arg = unpack(node)\
      if t == \"call\" then\
        return \"(\", self:values(arg), \")\"\
      elseif t == \"index\" then\
        return \"[\", self:value(arg), \"]\"\
      elseif t == \"dot\" then\
        return \".\", tostring(arg)\
      elseif t == \"colon\" then\
        return \":\", tostring(arg)\
      elseif t == \"colon_stub\" then\
        return user_error(\"Uncalled colon stub\")\
      else\
        return error(\"Unknown chain action: \" .. tostring(t))\
      end\
    end\
    if (callee_type == \"self\" or callee_type == \"self_class\") and node[3] and ntype(node[3]) == \"call\" then\
      callee[1] = callee_type .. \"_colon\"\
    end\
    local callee_value = self:value(callee)\
    if ntype(callee) == \"exp\" then\
      callee_value = self:line(\"(\", callee_value, \")\")\
    end\
    local actions\
    do\
      local _with_0 = self:line()\
      for _index_0 = item_offset, #node do\
        local action = node[_index_0]\
        _with_0:append(chain_item(action))\
      end\
      actions = _with_0\
    end\
    return self:line(callee_value, actions)\
  end,\
  fndef = function(self, node)\
    local args, whitelist, arrow, block = unpack(node, 2)\
    local default_args = { }\
    local self_args = { }\
    local arg_names\
    do\
      local _accum_0 = { }\
      local _len_0 = 1\
      for _index_0 = 1, #args do\
        local arg = args[_index_0]\
        local name, default_value = unpack(arg)\
        if type(name) == \"string\" then\
          name = name\
        else\
          if name[1] == \"self\" or name[1] == \"self_class\" then\
            insert(self_args, name)\
          end\
          name = name[2]\
        end\
        if default_value then\
          insert(default_args, arg)\
        end\
        local _value_0 = name\
        _accum_0[_len_0] = _value_0\
        _len_0 = _len_0 + 1\
      end\
      arg_names = _accum_0\
    end\
    if arrow == \"fat\" then\
      insert(arg_names, 1, \"self\")\
    end\
    do\
      local _with_0 = self:block()\
      if #whitelist > 0 then\
        _with_0:whitelist_names(whitelist)\
      end\
      for _index_0 = 1, #arg_names do\
        local name = arg_names[_index_0]\
        _with_0:put_name(name)\
      end\
      for _index_0 = 1, #default_args do\
        local default = default_args[_index_0]\
        local name, value = unpack(default)\
        if type(name) == \"table\" then\
          name = name[2]\
        end\
        _with_0:stm({\
          'if',\
          {\
            'exp',\
            {\
              \"ref\",\
              name\
            },\
            '==',\
            'nil'\
          },\
          {\
            {\
              'assign',\
              {\
                name\
              },\
              {\
                value\
              }\
            }\
          }\
        })\
      end\
      local self_arg_values\
      do\
        local _accum_0 = { }\
        local _len_0 = 1\
        for _index_0 = 1, #self_args do\
          local arg = self_args[_index_0]\
          _accum_0[_len_0] = arg[2]\
          _len_0 = _len_0 + 1\
        end\
        self_arg_values = _accum_0\
      end\
      if #self_args > 0 then\
        _with_0:stm({\
          \"assign\",\
          self_args,\
          self_arg_values\
        })\
      end\
      _with_0:stms(block)\
      if #args > #arg_names then\
        do\
          local _accum_0 = { }\
          local _len_0 = 1\
          for _index_0 = 1, #args do\
            local arg = args[_index_0]\
            _accum_0[_len_0] = arg[1]\
            _len_0 = _len_0 + 1\
          end\
          arg_names = _accum_0\
        end\
      end\
      _with_0.header = \"function(\" .. concat(arg_names, \", \") .. \")\"\
      return _with_0\
    end\
  end,\
  table = function(self, node)\
    local items = unpack(node, 2)\
    do\
      local _with_0 = self:block(\"{\", \"}\")\
      local format_line\
      format_line = function(tuple)\
        if #tuple == 2 then\
          local key, value = unpack(tuple)\
          if ntype(key) == \"key_literal\" and data.lua_keywords[key[2]] then\
            key = {\
              \"string\",\
              '\"',\
              key[2]\
            }\
          end\
          local assign\
          if ntype(key) == \"key_literal\" then\
            assign = key[2]\
          else\
            assign = self:line(\"[\", _with_0:value(key), \"]\")\
          end\
          local out = self:line(assign, \" = \", _with_0:value(value))\
          return out\
        else\
          return self:line(_with_0:value(tuple[1]))\
        end\
      end\
      if items then\
        local count = #items\
        for i, tuple in ipairs(items) do\
          local line = format_line(tuple)\
          if not (count == i) then\
            line:append(table_delim)\
          end\
          _with_0:add(line)\
        end\
      end\
      return _with_0\
    end\
  end,\
  minus = function(self, node)\
    return self:line(\"-\", self:value(node[2]))\
  end,\
  temp_name = function(self, node, ...)\
    return node:get_name(self, ...)\
  end,\
  number = function(self, node)\
    return node[2]\
  end,\
  bitnot = function(self, node)\
    return self:line(\"~\", self:value(node[2]))\
  end,\
  length = function(self, node)\
    return self:line(\"#\", self:value(node[2]))\
  end,\
  [\"not\"] = function(self, node)\
    return self:line(\"not \", self:value(node[2]))\
  end,\
  self = function(self, node)\
    return \"self.\" .. self:name(node[2])\
  end,\
  self_class = function(self, node)\
    return \"self.__class.\" .. self:name(node[2])\
  end,\
  self_colon = function(self, node)\
    return \"self:\" .. self:name(node[2])\
  end,\
  self_class_colon = function(self, node)\
    return \"self.__class:\" .. self:name(node[2])\
  end,\
  ref = function(self, value)\
    do\
      local sup = value[2] == \"super\" and self:get(\"super\")\
      if sup then\
        return self:value(sup(self))\
      end\
    end\
    return tostring(value[2])\
  end,\
  raw_value = function(self, value)\
    if value == \"...\" then\
      self:send(\"varargs\")\
    end\
    return tostring(value)\
  end\
}\
"
, '@'.."/usr/share/lua/5.3/moonscript/compile/value.lua" ) )

package.preload[ "moonscript.compile.statement" ] = assert( (loadstring or load)(
"local ntype\
ntype = require(\"moonscript.types\").ntype\
local concat, insert\
do\
  local _obj_0 = table\
  concat, insert = _obj_0.concat, _obj_0.insert\
end\
local unpack\
unpack = require(\"moonscript.util\").unpack\
return {\
  raw = function(self, node)\
    return self:add(node[2])\
  end,\
  lines = function(self, node)\
    local _list_0 = node[2]\
    for _index_0 = 1, #_list_0 do\
      local line = _list_0[_index_0]\
      self:add(line)\
    end\
  end,\
  declare = function(self, node)\
    local names = node[2]\
    local undeclared = self:declare(names)\
    if #undeclared > 0 then\
      do\
        local _with_0 = self:line(\"local \")\
        _with_0:append_list((function()\
          local _accum_0 = { }\
          local _len_0 = 1\
          for _index_0 = 1, #undeclared do\
            local name = undeclared[_index_0]\
            _accum_0[_len_0] = self:name(name)\
            _len_0 = _len_0 + 1\
          end\
          return _accum_0\
        end)(), \", \")\
        return _with_0\
      end\
    end\
  end,\
  declare_with_shadows = function(self, node)\
    local names = node[2]\
    self:declare(names)\
    do\
      local _with_0 = self:line(\"local \")\
      _with_0:append_list((function()\
        local _accum_0 = { }\
        local _len_0 = 1\
        for _index_0 = 1, #names do\
          local name = names[_index_0]\
          _accum_0[_len_0] = self:name(name)\
          _len_0 = _len_0 + 1\
        end\
        return _accum_0\
      end)(), \", \")\
      return _with_0\
    end\
  end,\
  assign = function(self, node)\
    local names, values = unpack(node, 2)\
    local undeclared = self:declare(names)\
    local declare = \"local \" .. concat(undeclared, \", \")\
    local has_fndef = false\
    local i = 1\
    while i <= #values do\
      if ntype(values[i]) == \"fndef\" then\
        has_fndef = true\
      end\
      i = i + 1\
    end\
    do\
      local _with_0 = self:line()\
      if #undeclared == #names and not has_fndef then\
        _with_0:append(declare)\
      else\
        if #undeclared > 0 then\
          self:add(declare, node[-1])\
        end\
        _with_0:append_list((function()\
          local _accum_0 = { }\
          local _len_0 = 1\
          for _index_0 = 1, #names do\
            local name = names[_index_0]\
            _accum_0[_len_0] = self:value(name)\
            _len_0 = _len_0 + 1\
          end\
          return _accum_0\
        end)(), \", \")\
      end\
      _with_0:append(\" = \")\
      _with_0:append_list((function()\
        local _accum_0 = { }\
        local _len_0 = 1\
        for _index_0 = 1, #values do\
          local v = values[_index_0]\
          _accum_0[_len_0] = self:value(v)\
          _len_0 = _len_0 + 1\
        end\
        return _accum_0\
      end)(), \", \")\
      return _with_0\
    end\
  end,\
  [\"return\"] = function(self, node)\
    return self:line(\"return \", (function()\
      if node[2] ~= \"\" then\
        return self:value(node[2])\
      end\
    end)())\
  end,\
  [\"break\"] = function(self, node)\
    return \"break\"\
  end,\
  [\"if\"] = function(self, node)\
    local cond, block = node[2], node[3]\
    local root\
    do\
      local _with_0 = self:block(self:line(\"if \", self:value(cond), \" then\"))\
      _with_0:stms(block)\
      root = _with_0\
    end\
    local current = root\
    local add_clause\
    add_clause = function(clause)\
      local type = clause[1]\
      local i = 2\
      local next\
      if type == \"else\" then\
        next = self:block(\"else\")\
      else\
        i = i + 1\
        next = self:block(self:line(\"elseif \", self:value(clause[2]), \" then\"))\
      end\
      next:stms(clause[i])\
      current.next = next\
      current = next\
    end\
    for _index_0 = 4, #node do\
      local cond = node[_index_0]\
      add_clause(cond)\
    end\
    return root\
  end,\
  [\"repeat\"] = function(self, node)\
    local cond, block = unpack(node, 2)\
    do\
      local _with_0 = self:block(\"repeat\", self:line(\"until \", self:value(cond)))\
      _with_0:stms(block)\
      return _with_0\
    end\
  end,\
  [\"while\"] = function(self, node)\
    local cond, block = unpack(node, 2)\
    do\
      local _with_0 = self:block(self:line(\"while \", self:value(cond), \" do\"))\
      _with_0:stms(block)\
      return _with_0\
    end\
  end,\
  [\"for\"] = function(self, node)\
    local name, bounds, block = unpack(node, 2)\
    local loop = self:line(\"for \", self:name(name), \" = \", self:value({\
      \"explist\",\
      unpack(bounds)\
    }), \" do\")\
    do\
      local _with_0 = self:block(loop)\
      _with_0:declare({\
        name\
      })\
      _with_0:stms(block)\
      return _with_0\
    end\
  end,\
  foreach = function(self, node)\
    local names, exps, block = unpack(node, 2)\
    local loop\
    do\
      local _with_0 = self:line()\
      _with_0:append(\"for \")\
      loop = _with_0\
    end\
    do\
      local _with_0 = self:block(loop)\
      loop:append_list((function()\
        local _accum_0 = { }\
        local _len_0 = 1\
        for _index_0 = 1, #names do\
          local name = names[_index_0]\
          _accum_0[_len_0] = _with_0:name(name, false)\
          _len_0 = _len_0 + 1\
        end\
        return _accum_0\
      end)(), \", \")\
      loop:append(\" in \")\
      loop:append_list((function()\
        local _accum_0 = { }\
        local _len_0 = 1\
        for _index_0 = 1, #exps do\
          local exp = exps[_index_0]\
          _accum_0[_len_0] = self:value(exp)\
          _len_0 = _len_0 + 1\
        end\
        return _accum_0\
      end)(), \",\")\
      loop:append(\" do\")\
      _with_0:declare(names)\
      _with_0:stms(block)\
      return _with_0\
    end\
  end,\
  export = function(self, node)\
    local names = unpack(node, 2)\
    if type(names) == \"string\" then\
      if names == \"*\" then\
        self.export_all = true\
      elseif names == \"^\" then\
        self.export_proper = true\
      end\
    else\
      self:declare(names)\
    end\
    return nil\
  end,\
  run = function(self, code)\
    code:call(self)\
    return nil\
  end,\
  group = function(self, node)\
    return self:stms(node[2])\
  end,\
  [\"do\"] = function(self, node)\
    do\
      local _with_0 = self:block()\
      _with_0:stms(node[2])\
      return _with_0\
    end\
  end,\
  noop = function(self) end\
}\
"
, '@'.."/usr/share/lua/5.3/moonscript/compile/statement.lua" ) )

package.preload[ "moonscript.parse" ] = assert( (loadstring or load)(
"local debug_grammar = false\
local lpeg = require(\"lpeg\")\
lpeg.setmaxstack(10000)\
local err_msg = \"Failed to parse:%s\\n [%d] >>    %s\"\
local Stack\
Stack = require(\"moonscript.data\").Stack\
local trim, pos_to_line, get_line\
do\
  local _obj_0 = require(\"moonscript.util\")\
  trim, pos_to_line, get_line = _obj_0.trim, _obj_0.pos_to_line, _obj_0.get_line\
end\
local unpack\
unpack = require(\"moonscript.util\").unpack\
local wrap_env\
wrap_env = require(\"moonscript.parse.env\").wrap_env\
local R, S, V, P, C, Ct, Cmt, Cg, Cb, Cc\
R, S, V, P, C, Ct, Cmt, Cg, Cb, Cc = lpeg.R, lpeg.S, lpeg.V, lpeg.P, lpeg.C, lpeg.Ct, lpeg.Cmt, lpeg.Cg, lpeg.Cb, lpeg.Cc\
local White, Break, Stop, Comment, Space, SomeSpace, SpaceBreak, EmptyLine, AlphaNum, Num, Shebang, L, _Name\
do\
  local _obj_0 = require(\"moonscript.parse.literals\")\
  White, Break, Stop, Comment, Space, SomeSpace, SpaceBreak, EmptyLine, AlphaNum, Num, Shebang, L, _Name = _obj_0.White, _obj_0.Break, _obj_0.Stop, _obj_0.Comment, _obj_0.Space, _obj_0.SomeSpace, _obj_0.SpaceBreak, _obj_0.EmptyLine, _obj_0.AlphaNum, _obj_0.Num, _obj_0.Shebang, _obj_0.L, _obj_0.Name\
end\
local SpaceName = Space * _Name\
Num = Space * (Num / function(v)\
  return {\
    \"number\",\
    v\
  }\
end)\
local Indent, Cut, ensure, extract_line, mark, pos, flatten_or_mark, is_assignable, check_assignable, format_assign, format_single_assign, sym, symx, simple_string, wrap_func_arg, join_chain, wrap_decorator, check_lua_string, self_assign, got\
do\
  local _obj_0 = require(\"moonscript.parse.util\")\
  Indent, Cut, ensure, extract_line, mark, pos, flatten_or_mark, is_assignable, check_assignable, format_assign, format_single_assign, sym, symx, simple_string, wrap_func_arg, join_chain, wrap_decorator, check_lua_string, self_assign, got = _obj_0.Indent, _obj_0.Cut, _obj_0.ensure, _obj_0.extract_line, _obj_0.mark, _obj_0.pos, _obj_0.flatten_or_mark, _obj_0.is_assignable, _obj_0.check_assignable, _obj_0.format_assign, _obj_0.format_single_assign, _obj_0.sym, _obj_0.symx, _obj_0.simple_string, _obj_0.wrap_func_arg, _obj_0.join_chain, _obj_0.wrap_decorator, _obj_0.check_lua_string, _obj_0.self_assign, _obj_0.got\
end\
local build_grammar = wrap_env(debug_grammar, function(root)\
  local _indent = Stack(0)\
  local _do_stack = Stack(0)\
  local state = {\
    last_pos = 0\
  }\
  local check_indent\
  check_indent = function(str, pos, indent)\
    state.last_pos = pos\
    return _indent:top() == indent\
  end\
  local advance_indent\
  advance_indent = function(str, pos, indent)\
    local top = _indent:top()\
    if top ~= -1 and indent > top then\
      _indent:push(indent)\
      return true\
    end\
  end\
  local push_indent\
  push_indent = function(str, pos, indent)\
    _indent:push(indent)\
    return true\
  end\
  local pop_indent\
  pop_indent = function()\
    assert(_indent:pop(), \"unexpected outdent\")\
    return true\
  end\
  local check_do\
  check_do = function(str, pos, do_node)\
    local top = _do_stack:top()\
    if top == nil or top then\
      return true, do_node\
    end\
    return false\
  end\
  local disable_do\
  disable_do = function()\
    _do_stack:push(false)\
    return true\
  end\
  local pop_do\
  pop_do = function()\
    assert(_do_stack:pop() ~= nil, \"unexpected do pop\")\
    return true\
  end\
  local DisableDo = Cmt(\"\", disable_do)\
  local PopDo = Cmt(\"\", pop_do)\
  local keywords = { }\
  local key\
  key = function(chars)\
    keywords[chars] = true\
    return Space * chars * -AlphaNum\
  end\
  local op\
  op = function(chars)\
    local patt = Space * C(chars)\
    if chars:match(\"^%w*$\") then\
      keywords[chars] = true\
      patt = patt * -AlphaNum\
    end\
    return patt\
  end\
  local Name = Cmt(SpaceName, function(str, pos, name)\
    if keywords[name] then\
      return false\
    end\
    return true\
  end) / trim\
  local SelfName = Space * \"@\" * (\"@\" * (_Name / mark(\"self_class\") + Cc(\"self.__class\")) + _Name / mark(\"self\") + Cc(\"self\"))\
  local KeyName = SelfName + Space * _Name / mark(\"key_literal\")\
  local VarArg = Space * P(\"...\") / trim\
  local g = P({\
    root or File,\
    File = Shebang ^ -1 * (Block + Ct(\"\")),\
    Block = Ct(Line * (Break ^ 1 * Line) ^ 0),\
    CheckIndent = Cmt(Indent, check_indent),\
    Line = (CheckIndent * Statement + Space * L(Stop)),\
    Statement = pos(Import + While + With + For + ForEach + Switch + Return + Local + Export + BreakLoop + Ct(ExpList) * (Update + Assign) ^ -1 / format_assign) * Space * ((key(\"if\") * Exp * (key(\"else\") * Exp) ^ -1 * Space / mark(\"if\") + key(\"unless\") * Exp / mark(\"unless\") + CompInner / mark(\"comprehension\")) * Space) ^ -1 / wrap_decorator,\
    Body = Space ^ -1 * Break * EmptyLine ^ 0 * InBlock + Ct(Statement),\
    Advance = L(Cmt(Indent, advance_indent)),\
    PushIndent = Cmt(Indent, push_indent),\
    PreventIndent = Cmt(Cc(-1), push_indent),\
    PopIndent = Cmt(\"\", pop_indent),\
    InBlock = Advance * Block * PopIndent,\
    Local = key(\"local\") * ((op(\"*\") + op(\"^\")) / mark(\"declare_glob\") + Ct(NameList) / mark(\"declare_with_shadows\")),\
    Import = key(\"import\") * Ct(ImportNameList) * SpaceBreak ^ 0 * key(\"from\") * Exp / mark(\"import\"),\
    ImportName = (sym(\"\\\\\") * Ct(Cc(\"colon\") * Name) + Name),\
    ImportNameList = SpaceBreak ^ 0 * ImportName * ((SpaceBreak ^ 1 + sym(\",\") * SpaceBreak ^ 0) * ImportName) ^ 0,\
    BreakLoop = Ct(key(\"break\") / trim) + Ct(key(\"continue\") / trim),\
    Return = key(\"return\") * (ExpListLow / mark(\"explist\") + C(\"\")) / mark(\"return\"),\
    WithExp = Ct(ExpList) * Assign ^ -1 / format_assign,\
    With = key(\"with\") * DisableDo * ensure(WithExp, PopDo) * key(\"do\") ^ -1 * Body / mark(\"with\"),\
    Switch = key(\"switch\") * DisableDo * ensure(Exp, PopDo) * key(\"do\") ^ -1 * Space ^ -1 * Break * SwitchBlock / mark(\"switch\"),\
    SwitchBlock = EmptyLine ^ 0 * Advance * Ct(SwitchCase * (Break ^ 1 * SwitchCase) ^ 0 * (Break ^ 1 * SwitchElse) ^ -1) * PopIndent,\
    SwitchCase = key(\"when\") * Ct(ExpList) * key(\"then\") ^ -1 * Body / mark(\"case\"),\
    SwitchElse = key(\"else\") * Body / mark(\"else\"),\
    IfCond = Exp * Assign ^ -1 / format_single_assign,\
    IfElse = (Break * EmptyLine ^ 0 * CheckIndent) ^ -1 * key(\"else\") * Body / mark(\"else\"),\
    IfElseIf = (Break * EmptyLine ^ 0 * CheckIndent) ^ -1 * key(\"elseif\") * pos(IfCond) * key(\"then\") ^ -1 * Body / mark(\"elseif\"),\
    If = key(\"if\") * IfCond * key(\"then\") ^ -1 * Body * IfElseIf ^ 0 * IfElse ^ -1 / mark(\"if\"),\
    Unless = key(\"unless\") * IfCond * key(\"then\") ^ -1 * Body * IfElseIf ^ 0 * IfElse ^ -1 / mark(\"unless\"),\
    While = key(\"while\") * DisableDo * ensure(Exp, PopDo) * key(\"do\") ^ -1 * Body / mark(\"while\"),\
    For = key(\"for\") * DisableDo * ensure(Name * sym(\"=\") * Ct(Exp * sym(\",\") * Exp * (sym(\",\") * Exp) ^ -1), PopDo) * key(\"do\") ^ -1 * Body / mark(\"for\"),\
    ForEach = key(\"for\") * Ct(AssignableNameList) * key(\"in\") * DisableDo * ensure(Ct(sym(\"*\") * Exp / mark(\"unpack\") + ExpList), PopDo) * key(\"do\") ^ -1 * Body / mark(\"foreach\"),\
    Do = key(\"do\") * Body / mark(\"do\"),\
    Comprehension = sym(\"[\") * Exp * CompInner * sym(\"]\") / mark(\"comprehension\"),\
    TblComprehension = sym(\"{\") * Ct(Exp * (sym(\",\") * Exp) ^ -1) * CompInner * sym(\"}\") / mark(\"tblcomprehension\"),\
    CompInner = Ct((CompForEach + CompFor) * CompClause ^ 0),\
    CompForEach = key(\"for\") * Ct(AssignableNameList) * key(\"in\") * (sym(\"*\") * Exp / mark(\"unpack\") + Exp) / mark(\"foreach\"),\
    CompFor = key(\"for\" * Name * sym(\"=\") * Ct(Exp * sym(\",\") * Exp * (sym(\",\") * Exp) ^ -1) / mark(\"for\")),\
    CompClause = CompFor + CompForEach + key(\"when\") * Exp / mark(\"when\"),\
    Assign = sym(\"=\") * (Ct(With + If + Switch) + Ct(TableBlock + ExpListLow)) / mark(\"assign\"),\
    Update = ((sym(\"..=\") + sym(\"+=\") + sym(\"-=\") + sym(\"*=\") + sym(\"/=\") + sym(\"%=\") + sym(\"or=\") + sym(\"and=\") + sym(\"&=\") + sym(\"|=\") + sym(\">>=\") + sym(\"<<=\")) / trim) * Exp / mark(\"update\"),\
    CharOperators = Space * C(S(\"+-*/%^><|&\")),\
    WordOperators = op(\"or\") + op(\"and\") + op(\"<=\") + op(\">=\") + op(\"~=\") + op(\"!=\") + op(\"==\") + op(\"..\") + op(\"<<\") + op(\">>\") + op(\"//\"),\
    BinaryOperator = (WordOperators + CharOperators) * SpaceBreak ^ 0,\
    Assignable = Cmt(Chain, check_assignable) + Name + SelfName,\
    Exp = Ct(Value * (BinaryOperator * Value) ^ 0) / flatten_or_mark(\"exp\"),\
    SimpleValue = If + Unless + Switch + With + ClassDecl + ForEach + For + While + Cmt(Do, check_do) + sym(\"-\") * -SomeSpace * Exp / mark(\"minus\") + sym(\"#\") * Exp / mark(\"length\") + sym(\"~\") * Exp / mark(\"bitnot\") + key(\"not\") * Exp / mark(\"not\") + TblComprehension + TableLit + Comprehension + FunLit + Num,\
    ChainValue = (Chain + Callable) * Ct(InvokeArgs ^ -1) / join_chain,\
    Value = pos(SimpleValue + Ct(KeyValueList) / mark(\"table\") + ChainValue + String),\
    SliceValue = Exp,\
    String = Space * DoubleString + Space * SingleString + LuaString,\
    SingleString = simple_string(\"'\"),\
    DoubleString = simple_string('\"', true),\
    LuaString = Cg(LuaStringOpen, \"string_open\") * Cb(\"string_open\") * Break ^ -1 * C((1 - Cmt(C(LuaStringClose) * Cb(\"string_open\"), check_lua_string)) ^ 0) * LuaStringClose / mark(\"string\"),\
    LuaStringOpen = sym(\"[\") * P(\"=\") ^ 0 * \"[\" / trim,\
    LuaStringClose = \"]\" * P(\"=\") ^ 0 * \"]\",\
    Callable = pos(Name / mark(\"ref\")) + SelfName + VarArg + Parens / mark(\"parens\"),\
    Parens = sym(\"(\") * SpaceBreak ^ 0 * Exp * SpaceBreak ^ 0 * sym(\")\"),\
    FnArgs = symx(\"(\") * SpaceBreak ^ 0 * Ct(FnArgsExpList ^ -1) * SpaceBreak ^ 0 * sym(\")\") + sym(\"!\") * -P(\"=\") * Ct(\"\"),\
    FnArgsExpList = Exp * ((Break + sym(\",\")) * White * Exp) ^ 0,\
    Chain = (Callable + String + -S(\".\\\\\")) * ChainItems / mark(\"chain\") + Space * (DotChainItem * ChainItems ^ -1 + ColonChain) / mark(\"chain\"),\
    ChainItems = ChainItem ^ 1 * ColonChain ^ -1 + ColonChain,\
    ChainItem = Invoke + DotChainItem + Slice + symx(\"[\") * Exp / mark(\"index\") * sym(\"]\"),\
    DotChainItem = symx(\".\") * _Name / mark(\"dot\"),\
    ColonChainItem = symx(\"\\\\\") * _Name / mark(\"colon\"),\
    ColonChain = ColonChainItem * (Invoke * ChainItems ^ -1) ^ -1,\
    Slice = symx(\"[\") * (SliceValue + Cc(1)) * sym(\",\") * (SliceValue + Cc(\"\")) * (sym(\",\") * SliceValue) ^ -1 * sym(\"]\") / mark(\"slice\"),\
    Invoke = FnArgs / mark(\"call\") + SingleString / wrap_func_arg + DoubleString / wrap_func_arg + L(P(\"[\")) * LuaString / wrap_func_arg,\
    TableValue = KeyValue + Ct(Exp),\
    TableLit = sym(\"{\") * Ct(TableValueList ^ -1 * sym(\",\") ^ -1 * (SpaceBreak * TableLitLine * (sym(\",\") ^ -1 * SpaceBreak * TableLitLine) ^ 0 * sym(\",\") ^ -1) ^ -1) * White * sym(\"}\") / mark(\"table\"),\
    TableValueList = TableValue * (sym(\",\") * TableValue) ^ 0,\
    TableLitLine = PushIndent * ((TableValueList * PopIndent) + (PopIndent * Cut)) + Space,\
    TableBlockInner = Ct(KeyValueLine * (SpaceBreak ^ 1 * KeyValueLine) ^ 0),\
    TableBlock = SpaceBreak ^ 1 * Advance * ensure(TableBlockInner, PopIndent) / mark(\"table\"),\
    ClassDecl = key(\"class\") * -P(\":\") * (Assignable + Cc(nil)) * (key(\"extends\") * PreventIndent * ensure(Exp, PopIndent) + C(\"\")) ^ -1 * (ClassBlock + Ct(\"\")) / mark(\"class\"),\
    ClassBlock = SpaceBreak ^ 1 * Advance * Ct(ClassLine * (SpaceBreak ^ 1 * ClassLine) ^ 0) * PopIndent,\
    ClassLine = CheckIndent * ((KeyValueList / mark(\"props\") + Statement / mark(\"stm\") + Exp / mark(\"stm\")) * sym(\",\") ^ -1),\
    Export = key(\"export\") * (Cc(\"class\") * ClassDecl + op(\"*\") + op(\"^\") + Ct(NameList) * (sym(\"=\") * Ct(ExpListLow)) ^ -1) / mark(\"export\"),\
    KeyValue = (sym(\":\") * -SomeSpace * Name * lpeg.Cp()) / self_assign + Ct((KeyName + sym(\"[\") * Exp * sym(\"]\") + Space * DoubleString + Space * SingleString) * symx(\":\") * (Exp + TableBlock + SpaceBreak ^ 1 * Exp)),\
    KeyValueList = KeyValue * (sym(\",\") * KeyValue) ^ 0,\
    KeyValueLine = CheckIndent * KeyValueList * sym(\",\") ^ -1,\
    FnArgsDef = sym(\"(\") * White * Ct(FnArgDefList ^ -1) * (key(\"using\") * Ct(NameList + Space * \"nil\") + Ct(\"\")) * White * sym(\")\") + Ct(\"\") * Ct(\"\"),\
    FnArgDefList = FnArgDef * ((sym(\",\") + Break) * White * FnArgDef) ^ 0 * ((sym(\",\") + Break) * White * Ct(VarArg)) ^ 0 + Ct(VarArg),\
    FnArgDef = Ct((Name + SelfName) * (sym(\"=\") * Exp) ^ -1),\
    FunLit = FnArgsDef * (sym(\"->\") * Cc(\"slim\") + sym(\"=>\") * Cc(\"fat\")) * (Body + Ct(\"\")) / mark(\"fndef\"),\
    NameList = Name * (sym(\",\") * Name) ^ 0,\
    NameOrDestructure = Name + TableLit,\
    AssignableNameList = NameOrDestructure * (sym(\",\") * NameOrDestructure) ^ 0,\
    ExpList = Exp * (sym(\",\") * Exp) ^ 0,\
    ExpListLow = Exp * ((sym(\",\") + sym(\";\")) * Exp) ^ 0,\
    InvokeArgs = -P(\"-\") * (ExpList * (sym(\",\") * (TableBlock + SpaceBreak * Advance * ArgBlock * TableBlock ^ -1) + TableBlock) ^ -1 + TableBlock),\
    ArgBlock = ArgLine * (sym(\",\") * SpaceBreak * ArgLine) ^ 0 * PopIndent,\
    ArgLine = CheckIndent * ExpList\
  })\
  return g, state\
end)\
local file_parser\
file_parser = function()\
  local g, state = build_grammar()\
  local file_grammar = White * g * White * -1\
  return {\
    match = function(self, str)\
      local tree\
      local _, err = xpcall((function()\
        tree = file_grammar:match(str)\
      end), function(err)\
        return debug.traceback(err, 2)\
      end)\
      if type(err) == \"string\" then\
        return nil, err\
      end\
      if not (tree) then\
        local msg\
        local err_pos = state.last_pos\
        if err then\
          local node\
          node, msg = unpack(err)\
          if msg then\
            msg = \" \" .. msg\
          end\
          err_pos = node[-1]\
        end\
        local line_no = pos_to_line(str, err_pos)\
        local line_str = get_line(str, line_no) or \"\"\
        return nil, err_msg:format(msg or \"\", line_no, trim(line_str))\
      end\
      return tree\
    end\
  }\
end\
return {\
  extract_line = extract_line,\
  build_grammar = build_grammar,\
  string = function(str)\
    return file_parser():match(str)\
  end\
}\
"
, '@'.."/usr/share/lua/5.3/moonscript/parse.lua" ) )

package.preload[ "moonscript.transform.comprehension" ] = assert( (loadstring or load)(
"local is_value\
is_value = require(\"moonscript.types\").is_value\
local construct_comprehension\
construct_comprehension = function(inner, clauses)\
  local current_stms = inner\
  for i = #clauses, 1, -1 do\
    local clause = clauses[i]\
    local t = clause[1]\
    local _exp_0 = t\
    if \"for\" == _exp_0 then\
      local _, name, bounds\
      _, name, bounds = clause[1], clause[2], clause[3]\
      current_stms = {\
        \"for\",\
        name,\
        bounds,\
        current_stms\
      }\
    elseif \"foreach\" == _exp_0 then\
      local _, names, iter\
      _, names, iter = clause[1], clause[2], clause[3]\
      current_stms = {\
        \"foreach\",\
        names,\
        {\
          iter\
        },\
        current_stms\
      }\
    elseif \"when\" == _exp_0 then\
      local _, cond\
      _, cond = clause[1], clause[2]\
      current_stms = {\
        \"if\",\
        cond,\
        current_stms\
      }\
    else\
      current_stms = error(\"Unknown comprehension clause: \" .. t)\
    end\
    current_stms = {\
      current_stms\
    }\
  end\
  return current_stms[1]\
end\
local comprehension_has_value\
comprehension_has_value = function(comp)\
  return is_value(comp[2])\
end\
return {\
  construct_comprehension = construct_comprehension,\
  comprehension_has_value = comprehension_has_value\
}\
"
, '@'.."/usr/share/lua/5.3/moonscript/transform/comprehension.lua" ) )

package.preload[ "moonscript.parse.util" ] = assert( (loadstring or load)(
"local unpack\
unpack = require(\"moonscript.util\").unpack\
local P, C, S, Cp, Cmt, V\
do\
  local _obj_0 = require(\"lpeg\")\
  P, C, S, Cp, Cmt, V = _obj_0.P, _obj_0.C, _obj_0.S, _obj_0.Cp, _obj_0.Cmt, _obj_0.V\
end\
local ntype\
ntype = require(\"moonscript.types\").ntype\
local Space\
Space = require(\"moonscript.parse.literals\").Space\
local Indent = C(S(\"\\t \") ^ 0) / function(str)\
  do\
    local sum = 0\
    for v in str:gmatch(\"[\\t ]\") do\
      local _exp_0 = v\
      if \" \" == _exp_0 then\
        sum = sum + 1\
      elseif \"\\t\" == _exp_0 then\
        sum = sum + 4\
      end\
    end\
    return sum\
  end\
end\
local Cut = P(function()\
  return false\
end)\
local ensure\
ensure = function(patt, finally)\
  return patt * finally + finally * Cut\
end\
local extract_line\
extract_line = function(str, start_pos)\
  str = str:sub(start_pos)\
  do\
    local m = str:match(\"^(.-)\\n\")\
    if m then\
      return m\
    end\
  end\
  return str:match(\"^.-$\")\
end\
local show_line_position\
show_line_position = function(str, pos, context)\
  if context == nil then\
    context = true\
  end\
  local lines = {\
    { }\
  }\
  for c in str:gmatch(\".\") do\
    lines[#lines] = lines[#lines] or { }\
    table.insert(lines[#lines], c)\
    if c == \"\\n\" then\
      lines[#lines + 1] = { }\
    end\
  end\
  for i, line in ipairs(lines) do\
    lines[i] = table.concat(line)\
  end\
  local out\
  local remaining = pos - 1\
  for k, line in ipairs(lines) do\
    if remaining < #line then\
      local left = line:sub(1, remaining)\
      local right = line:sub(remaining + 1)\
      out = {\
        tostring(left) .. \"◉\" .. tostring(right)\
      }\
      if context then\
        do\
          local before = lines[k - 1]\
          if before then\
            table.insert(out, 1, before)\
          end\
        end\
        do\
          local after = lines[k + 1]\
          if after then\
            table.insert(out, after)\
          end\
        end\
      end\
      break\
    else\
      remaining = remaining - #line\
    end\
  end\
  if not (out) then\
    return \"-\"\
  end\
  out = table.concat(out)\
  return (out:gsub(\"\\n*$\", \"\"))\
end\
local mark\
mark = function(name)\
  return function(...)\
    return {\
      name,\
      ...\
    }\
  end\
end\
local pos\
pos = function(patt)\
  return (Cp() * patt) / function(pos, value)\
    if type(value) == \"table\" then\
      value[-1] = pos\
    end\
    return value\
  end\
end\
local got\
got = function(what, context)\
  if context == nil then\
    context = true\
  end\
  return Cmt(\"\", function(str, pos)\
    print(\"++ got \" .. tostring(what), \"[\" .. tostring(show_line_position(str, pos, context)) .. \"]\")\
    return true\
  end)\
end\
local flatten_or_mark\
flatten_or_mark = function(name)\
  return function(tbl)\
    if #tbl == 1 then\
      return tbl[1]\
    end\
    table.insert(tbl, 1, name)\
    return tbl\
  end\
end\
local is_assignable\
do\
  local chain_assignable = {\
    index = true,\
    dot = true,\
    slice = true\
  }\
  is_assignable = function(node)\
    if node == \"...\" then\
      return false\
    end\
    local _exp_0 = ntype(node)\
    if \"ref\" == _exp_0 or \"self\" == _exp_0 or \"value\" == _exp_0 or \"self_class\" == _exp_0 or \"table\" == _exp_0 then\
      return true\
    elseif \"chain\" == _exp_0 then\
      return chain_assignable[ntype(node[#node])]\
    else\
      return false\
    end\
  end\
end\
local check_assignable\
check_assignable = function(str, pos, value)\
  if is_assignable(value) then\
    return true, value\
  else\
    return false\
  end\
end\
local format_assign\
do\
  local flatten_explist = flatten_or_mark(\"explist\")\
  format_assign = function(lhs_exps, assign)\
    if not (assign) then\
      return flatten_explist(lhs_exps)\
    end\
    for _index_0 = 1, #lhs_exps do\
      local assign_exp = lhs_exps[_index_0]\
      if not (is_assignable(assign_exp)) then\
        error({\
          assign_exp,\
          \"left hand expression is not assignable\"\
        })\
      end\
    end\
    local t = ntype(assign)\
    local _exp_0 = t\
    if \"assign\" == _exp_0 then\
      return {\
        \"assign\",\
        lhs_exps,\
        unpack(assign, 2)\
      }\
    elseif \"update\" == _exp_0 then\
      return {\
        \"update\",\
        lhs_exps[1],\
        unpack(assign, 2)\
      }\
    else\
      return error(\"unknown assign expression: \" .. tostring(t))\
    end\
  end\
end\
local format_single_assign\
format_single_assign = function(lhs, assign)\
  if assign then\
    return format_assign({\
      lhs\
    }, assign)\
  else\
    return lhs\
  end\
end\
local sym\
sym = function(chars)\
  return Space * chars\
end\
local symx\
symx = function(chars)\
  return chars\
end\
local simple_string\
simple_string = function(delim, allow_interpolation)\
  local inner = P(\"\\\\\" .. tostring(delim)) + \"\\\\\\\\\" + (1 - P(delim))\
  if allow_interpolation then\
    local interp = symx('#{') * V(\"Exp\") * sym('}')\
    inner = (C((inner - interp) ^ 1) + interp / mark(\"interpolate\")) ^ 0\
  else\
    inner = C(inner ^ 0)\
  end\
  return C(symx(delim)) * inner * sym(delim) / mark(\"string\")\
end\
local wrap_func_arg\
wrap_func_arg = function(value)\
  return {\
    \"call\",\
    {\
      value\
    }\
  }\
end\
local join_chain\
join_chain = function(callee, args)\
  if #args == 0 then\
    return callee\
  end\
  args = {\
    \"call\",\
    args\
  }\
  if ntype(callee) == \"chain\" then\
    table.insert(callee, args)\
    return callee\
  end\
  return {\
    \"chain\",\
    callee,\
    args\
  }\
end\
local wrap_decorator\
wrap_decorator = function(stm, dec)\
  if not (dec) then\
    return stm\
  end\
  return {\
    \"decorated\",\
    stm,\
    dec\
  }\
end\
local check_lua_string\
check_lua_string = function(str, pos, right, left)\
  return #left == #right\
end\
local self_assign\
self_assign = function(name, pos)\
  return {\
    {\
      \"key_literal\",\
      name\
    },\
    {\
      \"ref\",\
      name,\
      [-1] = pos\
    }\
  }\
end\
return {\
  Indent = Indent,\
  Cut = Cut,\
  ensure = ensure,\
  extract_line = extract_line,\
  mark = mark,\
  pos = pos,\
  flatten_or_mark = flatten_or_mark,\
  is_assignable = is_assignable,\
  check_assignable = check_assignable,\
  format_assign = format_assign,\
  format_single_assign = format_single_assign,\
  sym = sym,\
  symx = symx,\
  simple_string = simple_string,\
  wrap_func_arg = wrap_func_arg,\
  join_chain = join_chain,\
  wrap_decorator = wrap_decorator,\
  check_lua_string = check_lua_string,\
  self_assign = self_assign,\
  got = got,\
  show_line_position = show_line_position\
}\
"
, '@'.."/usr/share/lua/5.3/moonscript/parse/util.lua" ) )

package.preload[ "moonscript.types" ] = assert( (loadstring or load)(
"local util = require(\"moonscript.util\")\
local Set\
Set = require(\"moonscript.data\").Set\
local insert\
insert = table.insert\
local unpack\
unpack = util.unpack\
local manual_return = Set({\
  \"foreach\",\
  \"for\",\
  \"while\",\
  \"return\"\
})\
local cascading = Set({\
  \"if\",\
  \"unless\",\
  \"with\",\
  \"switch\",\
  \"class\",\
  \"do\"\
})\
local terminating = Set({\
  \"return\",\
  \"break\"\
})\
local ntype\
ntype = function(node)\
  local _exp_0 = type(node)\
  if \"nil\" == _exp_0 then\
    return \"nil\"\
  elseif \"table\" == _exp_0 then\
    return node[1]\
  else\
    return \"value\"\
  end\
end\
local mtype\
do\
  local moon_type = util.moon.type\
  mtype = function(val)\
    local mt = getmetatable(val)\
    if mt and mt.smart_node then\
      return \"table\"\
    end\
    return moon_type(val)\
  end\
end\
local value_can_be_statement\
value_can_be_statement = function(node)\
  if not (ntype(node) == \"chain\") then\
    return false\
  end\
  return ntype(node[#node]) == \"call\"\
end\
local is_value\
is_value = function(stm)\
  local compile = require(\"moonscript.compile\")\
  local transform = require(\"moonscript.transform\")\
  return compile.Block:is_value(stm) or transform.Value:can_transform(stm)\
end\
local value_is_singular\
value_is_singular = function(node)\
  return type(node) ~= \"table\" or node[1] ~= \"exp\" or #node == 2\
end\
local is_slice\
is_slice = function(node)\
  return ntype(node) == \"chain\" and ntype(node[#node]) == \"slice\"\
end\
local t = { }\
local node_types = {\
  class = {\
    {\
      \"name\",\
      \"Tmp\"\
    },\
    {\
      \"body\",\
      t\
    }\
  },\
  fndef = {\
    {\
      \"args\",\
      t\
    },\
    {\
      \"whitelist\",\
      t\
    },\
    {\
      \"arrow\",\
      \"slim\"\
    },\
    {\
      \"body\",\
      t\
    }\
  },\
  foreach = {\
    {\
      \"names\",\
      t\
    },\
    {\
      \"iter\"\
    },\
    {\
      \"body\",\
      t\
    }\
  },\
  [\"for\"] = {\
    {\
      \"name\"\
    },\
    {\
      \"bounds\",\
      t\
    },\
    {\
      \"body\",\
      t\
    }\
  },\
  [\"while\"] = {\
    {\
      \"cond\",\
      t\
    },\
    {\
      \"body\",\
      t\
    }\
  },\
  assign = {\
    {\
      \"names\",\
      t\
    },\
    {\
      \"values\",\
      t\
    }\
  },\
  declare = {\
    {\
      \"names\",\
      t\
    }\
  },\
  [\"if\"] = {\
    {\
      \"cond\",\
      t\
    },\
    {\
      \"then\",\
      t\
    }\
  }\
}\
local build_table\
build_table = function()\
  local key_table = { }\
  for node_name, args in pairs(node_types) do\
    local index = { }\
    for i, tuple in ipairs(args) do\
      local prop_name = tuple[1]\
      index[prop_name] = i + 1\
    end\
    key_table[node_name] = index\
  end\
  return key_table\
end\
local key_table = build_table()\
local make_builder\
make_builder = function(name)\
  local spec = node_types[name]\
  if not spec then\
    error(\"don't know how to build node: \" .. name)\
  end\
  return function(props)\
    if props == nil then\
      props = { }\
    end\
    local node = {\
      name\
    }\
    for i, arg in ipairs(spec) do\
      local key, default_value = unpack(arg)\
      local val\
      if props[key] then\
        val = props[key]\
      else\
        val = default_value\
      end\
      if val == t then\
        val = { }\
      end\
      node[i + 1] = val\
    end\
    return node\
  end\
end\
local build = nil\
build = setmetatable({\
  group = function(body)\
    if body == nil then\
      body = { }\
    end\
    return {\
      \"group\",\
      body\
    }\
  end,\
  [\"do\"] = function(body)\
    return {\
      \"do\",\
      body\
    }\
  end,\
  assign_one = function(name, value)\
    return build.assign({\
      names = {\
        name\
      },\
      values = {\
        value\
      }\
    })\
  end,\
  table = function(tbl)\
    if tbl == nil then\
      tbl = { }\
    end\
    for _index_0 = 1, #tbl do\
      local tuple = tbl[_index_0]\
      if type(tuple[1]) == \"string\" then\
        tuple[1] = {\
          \"key_literal\",\
          tuple[1]\
        }\
      end\
    end\
    return {\
      \"table\",\
      tbl\
    }\
  end,\
  block_exp = function(body)\
    return {\
      \"block_exp\",\
      body\
    }\
  end,\
  chain = function(parts)\
    local base = parts.base or error(\"expecting base property for chain\")\
    if type(base) == \"string\" then\
      base = {\
        \"ref\",\
        base\
      }\
    end\
    local node = {\
      \"chain\",\
      base\
    }\
    for _index_0 = 1, #parts do\
      local part = parts[_index_0]\
      insert(node, part)\
    end\
    return node\
  end\
}, {\
  __index = function(self, name)\
    self[name] = make_builder(name)\
    return rawget(self, name)\
  end\
})\
local smart_node_mt = setmetatable({ }, {\
  __index = function(self, node_type)\
    local index = key_table[node_type]\
    local mt = {\
      smart_node = true,\
      __index = function(node, key)\
        if index[key] then\
          return rawget(node, index[key])\
        elseif type(key) == \"string\" then\
          return error(\"unknown key: `\" .. key .. \"` on node type: `\" .. ntype(node) .. \"`\")\
        end\
      end,\
      __newindex = function(node, key, value)\
        if index[key] then\
          key = index[key]\
        end\
        return rawset(node, key, value)\
      end\
    }\
    self[node_type] = mt\
    return mt\
  end\
})\
local smart_node\
smart_node = function(node)\
  return setmetatable(node, smart_node_mt[ntype(node)])\
end\
local NOOP = {\
  \"noop\"\
}\
return {\
  ntype = ntype,\
  smart_node = smart_node,\
  build = build,\
  is_value = is_value,\
  is_slice = is_slice,\
  manual_return = manual_return,\
  cascading = cascading,\
  value_is_singular = value_is_singular,\
  value_can_be_statement = value_can_be_statement,\
  mtype = mtype,\
  terminating = terminating,\
  NOOP = NOOP\
}\
"
, '@'.."/usr/share/lua/5.3/moonscript/types.lua" ) )

package.preload[ "moonscript.parse.env" ] = assert( (loadstring or load)(
"local getfenv, setfenv\
do\
  local _obj_0 = require(\"moonscript.util\")\
  getfenv, setfenv = _obj_0.getfenv, _obj_0.setfenv\
end\
local wrap_env\
wrap_env = function(debug, fn)\
  local V, Cmt\
  do\
    local _obj_0 = require(\"lpeg\")\
    V, Cmt = _obj_0.V, _obj_0.Cmt\
  end\
  local env = getfenv(fn)\
  local wrap_name = V\
  if debug then\
    local indent = 0\
    local indent_char = \"  \"\
    local iprint\
    iprint = function(...)\
      local args = table.concat((function(...)\
        local _accum_0 = { }\
        local _len_0 = 1\
        local _list_0 = {\
          ...\
        }\
        for _index_0 = 1, #_list_0 do\
          local a = _list_0[_index_0]\
          _accum_0[_len_0] = tostring(a)\
          _len_0 = _len_0 + 1\
        end\
        return _accum_0\
      end)(...), \", \")\
      return io.stderr:write(tostring(indent_char:rep(indent)) .. tostring(args) .. \"\\n\")\
    end\
    wrap_name = function(name)\
      local v = V(name)\
      v = Cmt(\"\", function(str, pos)\
        local rest = str:sub(pos, -1):match(\"^([^\\n]*)\")\
        iprint(\"* \" .. tostring(name) .. \" (\" .. tostring(rest) .. \")\")\
        indent = indent + 1\
        return true\
      end) * Cmt(v, function(str, pos, ...)\
        iprint(name, true)\
        indent = indent - 1\
        return true, ...\
      end) + Cmt(\"\", function()\
        iprint(name, false)\
        indent = indent - 1\
        return false\
      end)\
      return v\
    end\
  end\
  return setfenv(fn, setmetatable({ }, {\
    __index = function(self, name)\
      local value = env[name]\
      if value ~= nil then\
        return value\
      end\
      if name:match(\"^[A-Z][A-Za-z0-9]*$\") then\
        local v = wrap_name(name)\
        return v\
      end\
      return error(\"unknown variable referenced: \" .. tostring(name))\
    end\
  }))\
end\
return {\
  wrap_env = wrap_env\
}\
"
, '@'.."/usr/share/lua/5.3/moonscript/parse/env.lua" ) )

package.preload[ "moonscript.transform" ] = assert( (loadstring or load)(
"return {\
  Statement = require(\"moonscript.transform.statement\"),\
  Value = require(\"moonscript.transform.value\")\
}\
"
, '@'.."/usr/share/lua/5.3/moonscript/transform.lua" ) )

package.preload[ "moonscript.transform.value" ] = assert( (loadstring or load)(
"local Transformer\
Transformer = require(\"moonscript.transform.transformer\").Transformer\
local build, ntype, smart_node\
do\
  local _obj_0 = require(\"moonscript.types\")\
  build, ntype, smart_node = _obj_0.build, _obj_0.ntype, _obj_0.smart_node\
end\
local NameProxy\
NameProxy = require(\"moonscript.transform.names\").NameProxy\
local Accumulator, default_accumulator\
do\
  local _obj_0 = require(\"moonscript.transform.accumulator\")\
  Accumulator, default_accumulator = _obj_0.Accumulator, _obj_0.default_accumulator\
end\
local lua_keywords\
lua_keywords = require(\"moonscript.data\").lua_keywords\
local Run, transform_last_stm, implicitly_return, chain_is_stub\
do\
  local _obj_0 = require(\"moonscript.transform.statements\")\
  Run, transform_last_stm, implicitly_return, chain_is_stub = _obj_0.Run, _obj_0.transform_last_stm, _obj_0.implicitly_return, _obj_0.chain_is_stub\
end\
local construct_comprehension\
construct_comprehension = require(\"moonscript.transform.comprehension\").construct_comprehension\
local insert\
insert = table.insert\
local unpack\
unpack = require(\"moonscript.util\").unpack\
return Transformer({\
  [\"for\"] = default_accumulator,\
  [\"while\"] = default_accumulator,\
  foreach = default_accumulator,\
  [\"do\"] = function(self, node)\
    return build.block_exp(node[2])\
  end,\
  decorated = function(self, node)\
    return self.transform.statement(node)\
  end,\
  class = function(self, node)\
    return build.block_exp({\
      node\
    })\
  end,\
  string = function(self, node)\
    local delim = node[2]\
    local convert_part\
    convert_part = function(part)\
      if type(part) == \"string\" or part == nil then\
        return {\
          \"string\",\
          delim,\
          part or \"\"\
        }\
      else\
        return build.chain({\
          base = \"tostring\",\
          {\
            \"call\",\
            {\
              part[2]\
            }\
          }\
        })\
      end\
    end\
    if #node <= 3 then\
      if type(node[3]) == \"string\" then\
        return node\
      else\
        return convert_part(node[3])\
      end\
    end\
    local e = {\
      \"exp\",\
      convert_part(node[3])\
    }\
    for i = 4, #node do\
      insert(e, \"..\")\
      insert(e, convert_part(node[i]))\
    end\
    return e\
  end,\
  comprehension = function(self, node)\
    local a = Accumulator()\
    node = self.transform.statement(node, function(exp)\
      return a:mutate_body({\
        exp\
      })\
    end)\
    return a:wrap(node)\
  end,\
  tblcomprehension = function(self, node)\
    local explist, clauses = unpack(node, 2)\
    local key_exp, value_exp = unpack(explist)\
    local accum = NameProxy(\"tbl\")\
    local inner\
    if value_exp then\
      local dest = build.chain({\
        base = accum,\
        {\
          \"index\",\
          key_exp\
        }\
      })\
      inner = {\
        build.assign_one(dest, value_exp)\
      }\
    else\
      local key_name, val_name = NameProxy(\"key\"), NameProxy(\"val\")\
      local dest = build.chain({\
        base = accum,\
        {\
          \"index\",\
          key_name\
        }\
      })\
      inner = {\
        build.assign({\
          names = {\
            key_name,\
            val_name\
          },\
          values = {\
            key_exp\
          }\
        }),\
        build.assign_one(dest, val_name)\
      }\
    end\
    return build.block_exp({\
      build.assign_one(accum, build.table()),\
      construct_comprehension(inner, clauses),\
      accum\
    })\
  end,\
  fndef = function(self, node)\
    smart_node(node)\
    node.body = transform_last_stm(node.body, implicitly_return(self))\
    node.body = {\
      Run(function(self)\
        return self:listen(\"varargs\", function() end)\
      end),\
      unpack(node.body)\
    }\
    return node\
  end,\
  [\"if\"] = function(self, node)\
    return build.block_exp({\
      node\
    })\
  end,\
  unless = function(self, node)\
    return build.block_exp({\
      node\
    })\
  end,\
  with = function(self, node)\
    return build.block_exp({\
      node\
    })\
  end,\
  switch = function(self, node)\
    return build.block_exp({\
      node\
    })\
  end,\
  chain = function(self, node)\
    for i = 2, #node do\
      local part = node[i]\
      if ntype(part) == \"dot\" and lua_keywords[part[2]] then\
        node[i] = {\
          \"index\",\
          {\
            \"string\",\
            '\"',\
            part[2]\
          }\
        }\
      end\
    end\
    if ntype(node[2]) == \"string\" then\
      node[2] = {\
        \"parens\",\
        node[2]\
      }\
    end\
    if chain_is_stub(node) then\
      local base_name = NameProxy(\"base\")\
      local fn_name = NameProxy(\"fn\")\
      local colon = table.remove(node)\
      local is_super = ntype(node[2]) == \"ref\" and node[2][2] == \"super\"\
      return build.block_exp({\
        build.assign({\
          names = {\
            base_name\
          },\
          values = {\
            node\
          }\
        }),\
        build.assign({\
          names = {\
            fn_name\
          },\
          values = {\
            build.chain({\
              base = base_name,\
              {\
                \"dot\",\
                colon[2]\
              }\
            })\
          }\
        }),\
        build.fndef({\
          args = {\
            {\
              \"...\"\
            }\
          },\
          body = {\
            build.chain({\
              base = fn_name,\
              {\
                \"call\",\
                {\
                  is_super and \"self\" or base_name,\
                  \"...\"\
                }\
              }\
            })\
          }\
        })\
      })\
    end\
  end,\
  block_exp = function(self, node)\
    local body = unpack(node, 2)\
    local fn = nil\
    local arg_list = { }\
    fn = smart_node(build.fndef({\
      body = {\
        Run(function(self)\
          return self:listen(\"varargs\", function()\
            insert(arg_list, \"...\")\
            insert(fn.args, {\
              \"...\"\
            })\
            return self:unlisten(\"varargs\")\
          end)\
        end),\
        unpack(body)\
      }\
    }))\
    return build.chain({\
      base = {\
        \"parens\",\
        fn\
      },\
      {\
        \"call\",\
        arg_list\
      }\
    })\
  end\
})\
"
, '@'.."/usr/share/lua/5.3/moonscript/transform/value.lua" ) )

package.preload[ "moonscript.transform.class" ] = assert( (loadstring or load)(
"local NameProxy, LocalName\
do\
  local _obj_0 = require(\"moonscript.transform.names\")\
  NameProxy, LocalName = _obj_0.NameProxy, _obj_0.LocalName\
end\
local Run\
Run = require(\"moonscript.transform.statements\").Run\
local CONSTRUCTOR_NAME = \"new\"\
local insert\
insert = table.insert\
local build, ntype, NOOP\
do\
  local _obj_0 = require(\"moonscript.types\")\
  build, ntype, NOOP = _obj_0.build, _obj_0.ntype, _obj_0.NOOP\
end\
local unpack\
unpack = require(\"moonscript.util\").unpack\
local transform_super\
transform_super = function(cls_name, on_base, block, chain)\
  if on_base == nil then\
    on_base = true\
  end\
  local relative_parent = {\
    \"chain\",\
    cls_name,\
    {\
      \"dot\",\
      \"__parent\"\
    }\
  }\
  if not (chain) then\
    return relative_parent\
  end\
  local chain_tail = {\
    unpack(chain, 3)\
  }\
  local head = chain_tail[1]\
  if head == nil then\
    return relative_parent\
  end\
  local new_chain = relative_parent\
  local _exp_0 = head[1]\
  if \"call\" == _exp_0 then\
    if on_base then\
      insert(new_chain, {\
        \"dot\",\
        \"__base\"\
      })\
    end\
    local calling_name = block:get(\"current_method\")\
    assert(calling_name, \"missing calling name\")\
    chain_tail[1] = {\
      \"call\",\
      {\
        \"self\",\
        unpack(head[2])\
      }\
    }\
    if ntype(calling_name) == \"key_literal\" then\
      insert(new_chain, {\
        \"dot\",\
        calling_name[2]\
      })\
    else\
      insert(new_chain, {\
        \"index\",\
        calling_name\
      })\
    end\
  elseif \"colon\" == _exp_0 then\
    local call = chain_tail[2]\
    if call and call[1] == \"call\" then\
      chain_tail[1] = {\
        \"dot\",\
        head[2]\
      }\
      chain_tail[2] = {\
        \"call\",\
        {\
          \"self\",\
          unpack(call[2])\
        }\
      }\
    end\
  end\
  for _index_0 = 1, #chain_tail do\
    local item = chain_tail[_index_0]\
    insert(new_chain, item)\
  end\
  return new_chain\
end\
local super_scope\
super_scope = function(value, t, key)\
  local prev_method\
  return {\
    \"scoped\",\
    Run(function(self)\
      prev_method = self:get(\"current_method\")\
      self:set(\"current_method\", key)\
      return self:set(\"super\", t)\
    end),\
    value,\
    Run(function(self)\
      return self:set(\"current_method\", prev_method)\
    end)\
  }\
end\
return function(self, node, ret, parent_assign)\
  local name, parent_val, body = unpack(node, 2)\
  if parent_val == \"\" then\
    parent_val = nil\
  end\
  local parent_cls_name = NameProxy(\"parent\")\
  local base_name = NameProxy(\"base\")\
  local self_name = NameProxy(\"self\")\
  local cls_name = NameProxy(\"class\")\
  local cls_instance_super\
  cls_instance_super = function(...)\
    return transform_super(cls_name, true, ...)\
  end\
  local cls_super\
  cls_super = function(...)\
    return transform_super(cls_name, false, ...)\
  end\
  local statements = { }\
  local properties = { }\
  for _index_0 = 1, #body do\
    local item = body[_index_0]\
    local _exp_0 = item[1]\
    if \"stm\" == _exp_0 then\
      insert(statements, item[2])\
    elseif \"props\" == _exp_0 then\
      for _index_1 = 2, #item do\
        local tuple = item[_index_1]\
        if ntype(tuple[1]) == \"self\" then\
          local k, v\
          k, v = tuple[1], tuple[2]\
          v = super_scope(v, cls_super, {\
            \"key_literal\",\
            k[2]\
          })\
          insert(statements, build.assign_one(k, v))\
        else\
          insert(properties, tuple)\
        end\
      end\
    end\
  end\
  local constructor\
  do\
    local _accum_0 = { }\
    local _len_0 = 1\
    for _index_0 = 1, #properties do\
      local _continue_0 = false\
      repeat\
        local tuple = properties[_index_0]\
        local key = tuple[1]\
        local _value_0\
        if key[1] == \"key_literal\" and key[2] == CONSTRUCTOR_NAME then\
          constructor = tuple[2]\
          _continue_0 = true\
          break\
        else\
          local val\
          key, val = tuple[1], tuple[2]\
          _value_0 = {\
            key,\
            super_scope(val, cls_instance_super, key)\
          }\
        end\
        _accum_0[_len_0] = _value_0\
        _len_0 = _len_0 + 1\
        _continue_0 = true\
      until true\
      if not _continue_0 then\
        break\
      end\
    end\
    properties = _accum_0\
  end\
  if not (constructor) then\
    if parent_val then\
      constructor = build.fndef({\
        args = {\
          {\
            \"...\"\
          }\
        },\
        arrow = \"fat\",\
        body = {\
          build.chain({\
            base = \"super\",\
            {\
              \"call\",\
              {\
                \"...\"\
              }\
            }\
          })\
        }\
      })\
    else\
      constructor = build.fndef()\
    end\
  end\
  local real_name = name or parent_assign and parent_assign[2][1]\
  local _exp_0 = ntype(real_name)\
  if \"chain\" == _exp_0 then\
    local last = real_name[#real_name]\
    local _exp_1 = ntype(last)\
    if \"dot\" == _exp_1 then\
      real_name = {\
        \"string\",\
        '\"',\
        last[2]\
      }\
    elseif \"index\" == _exp_1 then\
      real_name = last[2]\
    else\
      real_name = \"nil\"\
    end\
  elseif \"nil\" == _exp_0 then\
    real_name = \"nil\"\
  else\
    local name_t = type(real_name)\
    local flattened_name\
    if name_t == \"string\" then\
      flattened_name = real_name\
    elseif name_t == \"table\" and real_name[1] == \"ref\" then\
      flattened_name = real_name[2]\
    else\
      flattened_name = error(\"don't know how to extract name from \" .. tostring(name_t))\
    end\
    real_name = {\
      \"string\",\
      '\"',\
      flattened_name\
    }\
  end\
  local cls = build.table({\
    {\
      \"__init\",\
      super_scope(constructor, cls_super, {\
        \"key_literal\",\
        \"__init\"\
      })\
    },\
    {\
      \"__base\",\
      base_name\
    },\
    {\
      \"__name\",\
      real_name\
    },\
    parent_val and {\
      \"__parent\",\
      parent_cls_name\
    } or nil\
  })\
  local class_index\
  if parent_val then\
    local class_lookup = build[\"if\"]({\
      cond = {\
        \"exp\",\
        {\
          \"ref\",\
          \"val\"\
        },\
        \"==\",\
        \"nil\"\
      },\
      [\"then\"] = {\
        build.assign_one(LocalName(\"parent\"), build.chain({\
          base = \"rawget\",\
          {\
            \"call\",\
            {\
              {\
                \"ref\",\
                \"cls\"\
              },\
              {\
                \"string\",\
                '\"',\
                \"__parent\"\
              }\
            }\
          }\
        })),\
        build[\"if\"]({\
          cond = LocalName(\"parent\"),\
          [\"then\"] = {\
            build.chain({\
              base = LocalName(\"parent\"),\
              {\
                \"index\",\
                \"name\"\
              }\
            })\
          }\
        })\
      }\
    })\
    insert(class_lookup, {\
      \"else\",\
      {\
        \"val\"\
      }\
    })\
    class_index = build.fndef({\
      args = {\
        {\
          \"cls\"\
        },\
        {\
          \"name\"\
        }\
      },\
      body = {\
        build.assign_one(LocalName(\"val\"), build.chain({\
          base = \"rawget\",\
          {\
            \"call\",\
            {\
              base_name,\
              {\
                \"ref\",\
                \"name\"\
              }\
            }\
          }\
        })),\
        class_lookup\
      }\
    })\
  else\
    class_index = base_name\
  end\
  local cls_mt = build.table({\
    {\
      \"__index\",\
      class_index\
    },\
    {\
      \"__call\",\
      build.fndef({\
        args = {\
          {\
            \"cls\"\
          },\
          {\
            \"...\"\
          }\
        },\
        body = {\
          build.assign_one(self_name, build.chain({\
            base = \"setmetatable\",\
            {\
              \"call\",\
              {\
                \"{}\",\
                base_name\
              }\
            }\
          })),\
          build.chain({\
            base = \"cls.__init\",\
            {\
              \"call\",\
              {\
                self_name,\
                \"...\"\
              }\
            }\
          }),\
          self_name\
        }\
      })\
    }\
  })\
  cls = build.chain({\
    base = \"setmetatable\",\
    {\
      \"call\",\
      {\
        cls,\
        cls_mt\
      }\
    }\
  })\
  local value = nil\
  do\
    local out_body = {\
      Run(function(self)\
        if name then\
          return self:put_name(name)\
        end\
      end),\
      {\
        \"declare\",\
        {\
          cls_name\
        }\
      },\
      {\
        \"declare_glob\",\
        \"*\"\
      },\
      parent_val and build.assign_one(parent_cls_name, parent_val) or NOOP,\
      build.assign_one(base_name, {\
        \"table\",\
        properties\
      }),\
      build.assign_one(base_name:chain(\"__index\"), base_name),\
      parent_val and build.chain({\
        base = \"setmetatable\",\
        {\
          \"call\",\
          {\
            base_name,\
            build.chain({\
              base = parent_cls_name,\
              {\
                \"dot\",\
                \"__base\"\
              }\
            })\
          }\
        }\
      }) or NOOP,\
      build.assign_one(cls_name, cls),\
      build.assign_one(base_name:chain(\"__class\"), cls_name),\
      build.group((function()\
        if #statements > 0 then\
          return {\
            build.assign_one(LocalName(\"self\"), cls_name),\
            build.group(statements)\
          }\
        end\
      end)()),\
      parent_val and build[\"if\"]({\
        cond = {\
          \"exp\",\
          parent_cls_name:chain(\"__inherited\")\
        },\
        [\"then\"] = {\
          parent_cls_name:chain(\"__inherited\", {\
            \"call\",\
            {\
              parent_cls_name,\
              cls_name\
            }\
          })\
        }\
      }) or NOOP,\
      build.group((function()\
        if name then\
          return {\
            build.assign_one(name, cls_name)\
          }\
        end\
      end)()),\
      (function()\
        if ret then\
          return ret(cls_name)\
        end\
      end)()\
    }\
    value = build.group({\
      build.group((function()\
        if ntype(name) == \"value\" then\
          return {\
            build.declare({\
              names = {\
                name\
              }\
            })\
          }\
        end\
      end)()),\
      build[\"do\"](out_body)\
    })\
  end\
  return value\
end\
"
, '@'.."/usr/share/lua/5.3/moonscript/transform/class.lua" ) )

package.preload[ "moonscript.errors" ] = assert( (loadstring or load)(
"local util = require(\"moonscript.util\")\
local lpeg = require(\"lpeg\")\
local concat, insert\
do\
  local _obj_0 = table\
  concat, insert = _obj_0.concat, _obj_0.insert\
end\
local split, pos_to_line\
split, pos_to_line = util.split, util.pos_to_line\
local user_error\
user_error = function(...)\
  return error({\
    \"user-error\",\
    ...\
  })\
end\
local lookup_line\
lookup_line = function(fname, pos, cache)\
  if not cache[fname] then\
    do\
      local _with_0 = assert(io.open(fname))\
      cache[fname] = _with_0:read(\"*a\")\
      _with_0:close()\
    end\
  end\
  return pos_to_line(cache[fname], pos)\
end\
local reverse_line_number\
reverse_line_number = function(fname, line_table, line_num, cache)\
  for i = line_num, 0, -1 do\
    if line_table[i] then\
      return lookup_line(fname, line_table[i], cache)\
    end\
  end\
  return \"unknown\"\
end\
local truncate_traceback\
truncate_traceback = function(traceback, chunk_func)\
  if chunk_func == nil then\
    chunk_func = \"moonscript_chunk\"\
  end\
  traceback = split(traceback, \"\\n\")\
  local stop = #traceback\
  while stop > 1 do\
    if traceback[stop]:match(chunk_func) then\
      break\
    end\
    stop = stop - 1\
  end\
  do\
    local _accum_0 = { }\
    local _len_0 = 1\
    local _max_0 = stop\
    for _index_0 = 1, _max_0 < 0 and #traceback + _max_0 or _max_0 do\
      local t = traceback[_index_0]\
      _accum_0[_len_0] = t\
      _len_0 = _len_0 + 1\
    end\
    traceback = _accum_0\
  end\
  local rep = \"function '\" .. chunk_func .. \"'\"\
  traceback[#traceback] = traceback[#traceback]:gsub(rep, \"main chunk\")\
  return concat(traceback, \"\\n\")\
end\
local rewrite_traceback\
rewrite_traceback = function(text, err)\
  local line_tables = require(\"moonscript.line_tables\")\
  local V, S, Ct, C\
  V, S, Ct, C = lpeg.V, lpeg.S, lpeg.Ct, lpeg.C\
  local header_text = \"stack traceback:\"\
  local Header, Line = V(\"Header\"), V(\"Line\")\
  local Break = lpeg.S(\"\\n\")\
  local g = lpeg.P({\
    Header,\
    Header = header_text * Break * Ct(Line ^ 1),\
    Line = \"\\t\" * C((1 - Break) ^ 0) * (Break + -1)\
  })\
  local cache = { }\
  local rewrite_single\
  rewrite_single = function(trace)\
    local fname, line, msg = trace:match('^(.-):(%d+): (.*)$')\
    local tbl = line_tables[\"@\" .. tostring(fname)]\
    if fname and tbl then\
      return concat({\
        fname,\
        \":\",\
        reverse_line_number(fname, tbl, line, cache),\
        \": \",\
        \"(\",\
        line,\
        \") \",\
        msg\
      })\
    else\
      return trace\
    end\
  end\
  err = rewrite_single(err)\
  local match = g:match(text)\
  if not (match) then\
    return nil\
  end\
  for i, trace in ipairs(match) do\
    match[i] = rewrite_single(trace)\
  end\
  return concat({\
    \"moon: \" .. err,\
    header_text,\
    \"\\t\" .. concat(match, \"\\n\\t\")\
  }, \"\\n\")\
end\
return {\
  rewrite_traceback = rewrite_traceback,\
  truncate_traceback = truncate_traceback,\
  user_error = user_error,\
  reverse_line_number = reverse_line_number\
}\
"
, '@'.."/usr/share/lua/5.3/moonscript/errors.lua" ) )

package.preload[ "moonscript.data" ] = assert( (loadstring or load)(
"local concat, remove, insert\
do\
  local _obj_0 = table\
  concat, remove, insert = _obj_0.concat, _obj_0.remove, _obj_0.insert\
end\
local Set\
Set = function(items)\
  local _tbl_0 = { }\
  for _index_0 = 1, #items do\
    local k = items[_index_0]\
    _tbl_0[k] = true\
  end\
  return _tbl_0\
end\
local Stack\
do\
  local _class_0\
  local _base_0 = {\
    __tostring = function(self)\
      return \"<Stack {\" .. concat(self, \", \") .. \"}>\"\
    end,\
    pop = function(self)\
      return remove(self)\
    end,\
    push = function(self, value, ...)\
      insert(self, value)\
      if ... then\
        return self:push(...)\
      else\
        return value\
      end\
    end,\
    top = function(self)\
      return self[#self]\
    end\
  }\
  _base_0.__index = _base_0\
  _class_0 = setmetatable({\
    __init = function(self, ...)\
      self:push(...)\
      return nil\
    end,\
    __base = _base_0,\
    __name = \"Stack\"\
  }, {\
    __index = _base_0,\
    __call = function(cls, ...)\
      local _self_0 = setmetatable({}, _base_0)\
      cls.__init(_self_0, ...)\
      return _self_0\
    end\
  })\
  _base_0.__class = _class_0\
  Stack = _class_0\
end\
local lua_keywords = Set({\
  'and',\
  'break',\
  'do',\
  'else',\
  'elseif',\
  'end',\
  'false',\
  'for',\
  'function',\
  'if',\
  'in',\
  'local',\
  'nil',\
  'not',\
  'or',\
  'repeat',\
  'return',\
  'then',\
  'true',\
  'until',\
  'while'\
})\
return {\
  Set = Set,\
  Stack = Stack,\
  lua_keywords = lua_keywords\
}\
"
, '@'.."/usr/share/lua/5.3/moonscript/data.lua" ) )

package.preload[ "moonscript.transform.accumulator" ] = assert( (loadstring or load)(
"local types = require(\"moonscript.types\")\
local build, ntype, NOOP\
build, ntype, NOOP = types.build, types.ntype, types.NOOP\
local NameProxy\
NameProxy = require(\"moonscript.transform.names\").NameProxy\
local insert\
insert = table.insert\
local is_singular\
is_singular = function(body)\
  if #body ~= 1 then\
    return false\
  end\
  if \"group\" == ntype(body) then\
    return is_singular(body[2])\
  else\
    return body[1]\
  end\
end\
local transform_last_stm\
transform_last_stm = require(\"moonscript.transform.statements\").transform_last_stm\
local Accumulator\
do\
  local _class_0\
  local _base_0 = {\
    body_idx = {\
      [\"for\"] = 4,\
      [\"while\"] = 3,\
      foreach = 4\
    },\
    convert = function(self, node)\
      local index = self.body_idx[ntype(node)]\
      node[index] = self:mutate_body(node[index])\
      return self:wrap(node)\
    end,\
    wrap = function(self, node, group_type)\
      if group_type == nil then\
        group_type = \"block_exp\"\
      end\
      return build[group_type]({\
        build.assign_one(self.accum_name, build.table()),\
        build.assign_one(self.len_name, 1),\
        node,\
        group_type == \"block_exp\" and self.accum_name or NOOP\
      })\
    end,\
    mutate_body = function(self, body)\
      local single_stm = is_singular(body)\
      local val\
      if single_stm and types.is_value(single_stm) then\
        body = { }\
        val = single_stm\
      else\
        body = transform_last_stm(body, function(n)\
          if types.is_value(n) then\
            return build.assign_one(self.value_name, n)\
          else\
            return build.group({\
              {\
                \"declare\",\
                {\
                  self.value_name\
                }\
              },\
              n\
            })\
          end\
        end)\
        val = self.value_name\
      end\
      local update = {\
        build.assign_one(NameProxy.index(self.accum_name, self.len_name), val),\
        {\
          \"update\",\
          self.len_name,\
          \"+=\",\
          1\
        }\
      }\
      insert(body, build.group(update))\
      return body\
    end\
  }\
  _base_0.__index = _base_0\
  _class_0 = setmetatable({\
    __init = function(self, accum_name)\
      self.accum_name = NameProxy(\"accum\")\
      self.value_name = NameProxy(\"value\")\
      self.len_name = NameProxy(\"len\")\
    end,\
    __base = _base_0,\
    __name = \"Accumulator\"\
  }, {\
    __index = _base_0,\
    __call = function(cls, ...)\
      local _self_0 = setmetatable({}, _base_0)\
      cls.__init(_self_0, ...)\
      return _self_0\
    end\
  })\
  _base_0.__class = _class_0\
  Accumulator = _class_0\
end\
local default_accumulator\
default_accumulator = function(self, node)\
  return Accumulator():convert(node)\
end\
return {\
  Accumulator = Accumulator,\
  default_accumulator = default_accumulator\
}\
"
, '@'.."/usr/share/lua/5.3/moonscript/transform/accumulator.lua" ) )

package.preload[ "moonscript.init" ] = assert( (loadstring or load)(
"do\
  local _with_0 = require(\"moonscript.base\")\
  _with_0.insert_loader()\
  return _with_0\
end\
"
, '@'.."/usr/share/lua/5.3/moonscript/init.lua" ) )

package.preload[ "moonscript.transform.statements" ] = assert( (loadstring or load)(
"local types = require(\"moonscript.types\")\
local ntype, mtype, is_value, NOOP\
ntype, mtype, is_value, NOOP = types.ntype, types.mtype, types.is_value, types.NOOP\
local comprehension_has_value\
comprehension_has_value = require(\"moonscript.transform.comprehension\").comprehension_has_value\
local Run\
do\
  local _class_0\
  local _base_0 = {\
    call = function(self, state)\
      return self.fn(state)\
    end\
  }\
  _base_0.__index = _base_0\
  _class_0 = setmetatable({\
    __init = function(self, fn)\
      self.fn = fn\
      self[1] = \"run\"\
    end,\
    __base = _base_0,\
    __name = \"Run\"\
  }, {\
    __index = _base_0,\
    __call = function(cls, ...)\
      local _self_0 = setmetatable({}, _base_0)\
      cls.__init(_self_0, ...)\
      return _self_0\
    end\
  })\
  _base_0.__class = _class_0\
  Run = _class_0\
end\
local last_stm\
last_stm = function(stms)\
  local last_exp_id = 0\
  for i = #stms, 1, -1 do\
    local stm = stms[i]\
    if stm and mtype(stm) ~= Run then\
      if ntype(stm) == \"group\" then\
        return last_stm(stm[2])\
      end\
      last_exp_id = i\
      break\
    end\
  end\
  return stms[last_exp_id], last_exp_id, stms\
end\
local transform_last_stm\
transform_last_stm = function(stms, fn)\
  local _, last_idx, _stms = last_stm(stms)\
  if _stms ~= stms then\
    error(\"cannot transform last node in group\")\
  end\
  return (function()\
    local _accum_0 = { }\
    local _len_0 = 1\
    for i, stm in ipairs(stms) do\
      if i == last_idx then\
        _accum_0[_len_0] = {\
          \"transform\",\
          stm,\
          fn\
        }\
      else\
        _accum_0[_len_0] = stm\
      end\
      _len_0 = _len_0 + 1\
    end\
    return _accum_0\
  end)()\
end\
local chain_is_stub\
chain_is_stub = function(chain)\
  local stub = chain[#chain]\
  return stub and ntype(stub) == \"colon\"\
end\
local implicitly_return\
implicitly_return = function(scope)\
  local is_top = true\
  local fn\
  fn = function(stm)\
    local t = ntype(stm)\
    if t == \"decorated\" then\
      stm = scope.transform.statement(stm)\
      t = ntype(stm)\
    end\
    if types.cascading[t] then\
      is_top = false\
      return scope.transform.statement(stm, fn)\
    elseif types.manual_return[t] or not is_value(stm) then\
      if is_top and t == \"return\" and stm[2] == \"\" then\
        return NOOP\
      else\
        return stm\
      end\
    else\
      if t == \"comprehension\" and not comprehension_has_value(stm) then\
        return stm\
      else\
        return {\
          \"return\",\
          stm\
        }\
      end\
    end\
  end\
  return fn\
end\
return {\
  Run = Run,\
  last_stm = last_stm,\
  transform_last_stm = transform_last_stm,\
  chain_is_stub = chain_is_stub,\
  implicitly_return = implicitly_return\
}\
"
, '@'.."/usr/share/lua/5.3/moonscript/transform/statements.lua" ) )

package.preload[ "moonscript.compile" ] = assert( (loadstring or load)(
"local util = require(\"moonscript.util\")\
local dump = require(\"moonscript.dump\")\
local transform = require(\"moonscript.transform\")\
local NameProxy, LocalName\
do\
  local _obj_0 = require(\"moonscript.transform.names\")\
  NameProxy, LocalName = _obj_0.NameProxy, _obj_0.LocalName\
end\
local Set\
Set = require(\"moonscript.data\").Set\
local ntype, value_can_be_statement\
do\
  local _obj_0 = require(\"moonscript.types\")\
  ntype, value_can_be_statement = _obj_0.ntype, _obj_0.value_can_be_statement\
end\
local statement_compilers = require(\"moonscript.compile.statement\")\
local value_compilers = require(\"moonscript.compile.value\")\
local concat, insert\
do\
  local _obj_0 = table\
  concat, insert = _obj_0.concat, _obj_0.insert\
end\
local pos_to_line, get_closest_line, trim, unpack\
pos_to_line, get_closest_line, trim, unpack = util.pos_to_line, util.get_closest_line, util.trim, util.unpack\
local mtype = util.moon.type\
local indent_char = \"  \"\
local Line, DelayedLine, Lines, Block, RootBlock\
do\
  local _class_0\
  local _base_0 = {\
    mark_pos = function(self, pos, line)\
      if line == nil then\
        line = #self\
      end\
      if not (self.posmap[line]) then\
        self.posmap[line] = pos\
      end\
    end,\
    add = function(self, item)\
      local _exp_0 = mtype(item)\
      if Line == _exp_0 then\
        item:render(self)\
      elseif Block == _exp_0 then\
        item:render(self)\
      else\
        self[#self + 1] = item\
      end\
      return self\
    end,\
    flatten_posmap = function(self, line_no, out)\
      if line_no == nil then\
        line_no = 0\
      end\
      if out == nil then\
        out = { }\
      end\
      local posmap = self.posmap\
      for i, l in ipairs(self) do\
        local _exp_0 = mtype(l)\
        if \"string\" == _exp_0 or DelayedLine == _exp_0 then\
          line_no = line_no + 1\
          out[line_no] = posmap[i]\
          for _ in l:gmatch(\"\\n\") do\
            line_no = line_no + 1\
          end\
          out[line_no] = posmap[i]\
        elseif Lines == _exp_0 then\
          local _\
          _, line_no = l:flatten_posmap(line_no, out)\
        else\
          error(\"Unknown item in Lines: \" .. tostring(l))\
        end\
      end\
      return out, line_no\
    end,\
    flatten = function(self, indent, buffer)\
      if indent == nil then\
        indent = nil\
      end\
      if buffer == nil then\
        buffer = { }\
      end\
      for i = 1, #self do\
        local l = self[i]\
        local t = mtype(l)\
        if t == DelayedLine then\
          l = l:render()\
          t = \"string\"\
        end\
        local _exp_0 = t\
        if \"string\" == _exp_0 then\
          if indent then\
            insert(buffer, indent)\
          end\
          insert(buffer, l)\
          if \"string\" == type(self[i + 1]) then\
            local lc = l:sub(-1)\
            if (lc == \")\" or lc == \"]\") and self[i + 1]:sub(1, 1) == \"(\" then\
              insert(buffer, \";\")\
            end\
          end\
          insert(buffer, \"\\n\")\
        elseif Lines == _exp_0 then\
          l:flatten(indent and indent .. indent_char or indent_char, buffer)\
        else\
          error(\"Unknown item in Lines: \" .. tostring(l))\
        end\
      end\
      return buffer\
    end,\
    __tostring = function(self)\
      local strip\
      strip = function(t)\
        if \"table\" == type(t) then\
          local _accum_0 = { }\
          local _len_0 = 1\
          for _index_0 = 1, #t do\
            local v = t[_index_0]\
            _accum_0[_len_0] = strip(v)\
            _len_0 = _len_0 + 1\
          end\
          return _accum_0\
        else\
          return t\
        end\
      end\
      return \"Lines<\" .. tostring(util.dump(strip(self)):sub(1, -2)) .. \">\"\
    end\
  }\
  _base_0.__index = _base_0\
  _class_0 = setmetatable({\
    __init = function(self)\
      self.posmap = { }\
    end,\
    __base = _base_0,\
    __name = \"Lines\"\
  }, {\
    __index = _base_0,\
    __call = function(cls, ...)\
      local _self_0 = setmetatable({}, _base_0)\
      cls.__init(_self_0, ...)\
      return _self_0\
    end\
  })\
  _base_0.__class = _class_0\
  Lines = _class_0\
end\
do\
  local _class_0\
  local _base_0 = {\
    pos = nil,\
    append_list = function(self, items, delim)\
      for i = 1, #items do\
        self:append(items[i])\
        if i < #items then\
          insert(self, delim)\
        end\
      end\
      return nil\
    end,\
    append = function(self, first, ...)\
      if Line == mtype(first) then\
        if not (self.pos) then\
          self.pos = first.pos\
        end\
        for _index_0 = 1, #first do\
          local value = first[_index_0]\
          self:append(value)\
        end\
      else\
        insert(self, first)\
      end\
      if ... then\
        return self:append(...)\
      end\
    end,\
    render = function(self, buffer)\
      local current = { }\
      local add_current\
      add_current = function()\
        buffer:add(concat(current))\
        return buffer:mark_pos(self.pos)\
      end\
      for _index_0 = 1, #self do\
        local chunk = self[_index_0]\
        local _exp_0 = mtype(chunk)\
        if Block == _exp_0 then\
          local _list_0 = chunk:render(Lines())\
          for _index_1 = 1, #_list_0 do\
            local block_chunk = _list_0[_index_1]\
            if \"string\" == type(block_chunk) then\
              insert(current, block_chunk)\
            else\
              add_current()\
              buffer:add(block_chunk)\
              current = { }\
            end\
          end\
        else\
          insert(current, chunk)\
        end\
      end\
      if current[1] then\
        add_current()\
      end\
      return buffer\
    end,\
    __tostring = function(self)\
      return \"Line<\" .. tostring(util.dump(self):sub(1, -2)) .. \">\"\
    end\
  }\
  _base_0.__index = _base_0\
  _class_0 = setmetatable({\
    __init = function() end,\
    __base = _base_0,\
    __name = \"Line\"\
  }, {\
    __index = _base_0,\
    __call = function(cls, ...)\
      local _self_0 = setmetatable({}, _base_0)\
      cls.__init(_self_0, ...)\
      return _self_0\
    end\
  })\
  _base_0.__class = _class_0\
  Line = _class_0\
end\
do\
  local _class_0\
  local _base_0 = {\
    prepare = function() end,\
    render = function(self)\
      self:prepare()\
      return concat(self)\
    end\
  }\
  _base_0.__index = _base_0\
  _class_0 = setmetatable({\
    __init = function(self, fn)\
      self.prepare = fn\
    end,\
    __base = _base_0,\
    __name = \"DelayedLine\"\
  }, {\
    __index = _base_0,\
    __call = function(cls, ...)\
      local _self_0 = setmetatable({}, _base_0)\
      cls.__init(_self_0, ...)\
      return _self_0\
    end\
  })\
  _base_0.__class = _class_0\
  DelayedLine = _class_0\
end\
do\
  local _class_0\
  local _base_0 = {\
    header = \"do\",\
    footer = \"end\",\
    export_all = false,\
    export_proper = false,\
    value_compilers = value_compilers,\
    statement_compilers = statement_compilers,\
    __tostring = function(self)\
      local h\
      if \"string\" == type(self.header) then\
        h = self.header\
      else\
        h = unpack(self.header:render({ }))\
      end\
      return \"Block<\" .. tostring(h) .. \"> <- \" .. tostring(self.parent)\
    end,\
    set = function(self, name, value)\
      self._state[name] = value\
    end,\
    get = function(self, name)\
      return self._state[name]\
    end,\
    get_current = function(self, name)\
      return rawget(self._state, name)\
    end,\
    listen = function(self, name, fn)\
      self._listeners[name] = fn\
    end,\
    unlisten = function(self, name)\
      self._listeners[name] = nil\
    end,\
    send = function(self, name, ...)\
      do\
        local fn = self._listeners[name]\
        if fn then\
          return fn(self, ...)\
        end\
      end\
    end,\
    extract_assign_name = function(self, node)\
      local is_local = false\
      local real_name\
      local _exp_0 = mtype(node)\
      if LocalName == _exp_0 then\
        is_local = true\
        real_name = node:get_name(self)\
      elseif NameProxy == _exp_0 then\
        real_name = node:get_name(self)\
      elseif \"table\" == _exp_0 then\
        real_name = node[1] == \"ref\" and node[2]\
      elseif \"string\" == _exp_0 then\
        real_name = node\
      end\
      return real_name, is_local\
    end,\
    declare = function(self, names)\
      local undeclared\
      do\
        local _accum_0 = { }\
        local _len_0 = 1\
        for _index_0 = 1, #names do\
          local _continue_0 = false\
          repeat\
            local name = names[_index_0]\
            local real_name, is_local = self:extract_assign_name(name)\
            if not (is_local or real_name and not self:has_name(real_name, true)) then\
              _continue_0 = true\
              break\
            end\
            self:put_name(real_name)\
            if self:name_exported(real_name) then\
              _continue_0 = true\
              break\
            end\
            local _value_0 = real_name\
            _accum_0[_len_0] = _value_0\
            _len_0 = _len_0 + 1\
            _continue_0 = true\
          until true\
          if not _continue_0 then\
            break\
          end\
        end\
        undeclared = _accum_0\
      end\
      return undeclared\
    end,\
    whitelist_names = function(self, names)\
      self._name_whitelist = Set(names)\
    end,\
    name_exported = function(self, name)\
      if self.export_all then\
        return true\
      end\
      if self.export_proper and name:match(\"^%u\") then\
        return true\
      end\
    end,\
    put_name = function(self, name, ...)\
      local value = ...\
      if select(\"#\", ...) == 0 then\
        value = true\
      end\
      if NameProxy == mtype(name) then\
        name = name:get_name(self)\
      end\
      self._names[name] = value\
    end,\
    has_name = function(self, name, skip_exports)\
      if not skip_exports and self:name_exported(name) then\
        return true\
      end\
      local yes = self._names[name]\
      if yes == nil and self.parent then\
        if not self._name_whitelist or self._name_whitelist[name] then\
          return self.parent:has_name(name, true)\
        end\
      else\
        return yes\
      end\
    end,\
    is_local = function(self, node)\
      local t = mtype(node)\
      if t == \"string\" then\
        return self:has_name(node, false)\
      end\
      if t == NameProxy or t == LocalName then\
        return true\
      end\
      if t == \"table\" then\
        if node[1] == \"ref\" or (node[1] == \"chain\" and #node == 2) then\
          return self:is_local(node[2])\
        end\
      end\
      return false\
    end,\
    free_name = function(self, prefix, dont_put)\
      prefix = prefix or \"moon\"\
      local searching = true\
      local name, i = nil, 0\
      while searching do\
        name = concat({\
          \"\",\
          prefix,\
          i\
        }, \"_\")\
        i = i + 1\
        searching = self:has_name(name, true)\
      end\
      if not dont_put then\
        self:put_name(name)\
      end\
      return name\
    end,\
    init_free_var = function(self, prefix, value)\
      local name = self:free_name(prefix, true)\
      self:stm({\
        \"assign\",\
        {\
          name\
        },\
        {\
          value\
        }\
      })\
      return name\
    end,\
    add = function(self, item, pos)\
      do\
        local _with_0 = self._lines\
        _with_0:add(item)\
        if pos then\
          _with_0:mark_pos(pos)\
        end\
      end\
      return item\
    end,\
    render = function(self, buffer)\
      buffer:add(self.header)\
      buffer:mark_pos(self.pos)\
      if self.next then\
        buffer:add(self._lines)\
        self.next:render(buffer)\
      else\
        if #self._lines == 0 and \"string\" == type(buffer[#buffer]) then\
          buffer[#buffer] = buffer[#buffer] .. (\" \" .. (unpack(Lines():add(self.footer))))\
        else\
          buffer:add(self._lines)\
          buffer:add(self.footer)\
          buffer:mark_pos(self.pos)\
        end\
      end\
      return buffer\
    end,\
    block = function(self, header, footer)\
      return Block(self, header, footer)\
    end,\
    line = function(self, ...)\
      do\
        local _with_0 = Line()\
        _with_0:append(...)\
        return _with_0\
      end\
    end,\
    is_stm = function(self, node)\
      return self.statement_compilers[ntype(node)] ~= nil\
    end,\
    is_value = function(self, node)\
      local t = ntype(node)\
      return self.value_compilers[t] ~= nil or t == \"value\"\
    end,\
    name = function(self, node, ...)\
      if type(node) == \"string\" then\
        return node\
      else\
        return self:value(node, ...)\
      end\
    end,\
    value = function(self, node, ...)\
      node = self.transform.value(node)\
      local action\
      if type(node) ~= \"table\" then\
        action = \"raw_value\"\
      else\
        action = node[1]\
      end\
      local fn = self.value_compilers[action]\
      if not (fn) then\
        error({\
          \"compile-error\",\
          \"Failed to find value compiler for: \" .. dump.value(node),\
          node[-1]\
        })\
      end\
      local out = fn(self, node, ...)\
      if type(node) == \"table\" and node[-1] then\
        if type(out) == \"string\" then\
          do\
            local _with_0 = Line()\
            _with_0:append(out)\
            out = _with_0\
          end\
        end\
        out.pos = node[-1]\
      end\
      return out\
    end,\
    values = function(self, values, delim)\
      delim = delim or ', '\
      do\
        local _with_0 = Line()\
        _with_0:append_list((function()\
          local _accum_0 = { }\
          local _len_0 = 1\
          for _index_0 = 1, #values do\
            local v = values[_index_0]\
            _accum_0[_len_0] = self:value(v)\
            _len_0 = _len_0 + 1\
          end\
          return _accum_0\
        end)(), delim)\
        return _with_0\
      end\
    end,\
    stm = function(self, node, ...)\
      if not node then\
        return \
      end\
      node = self.transform.statement(node)\
      local result\
      do\
        local fn = self.statement_compilers[ntype(node)]\
        if fn then\
          result = fn(self, node, ...)\
        else\
          if value_can_be_statement(node) then\
            result = self:value(node)\
          else\
            result = self:stm({\
              \"assign\",\
              {\
                \"_\"\
              },\
              {\
                node\
              }\
            })\
          end\
        end\
      end\
      if result then\
        if type(node) == \"table\" and type(result) == \"table\" and node[-1] then\
          result.pos = node[-1]\
        end\
        self:add(result)\
      end\
      return nil\
    end,\
    stms = function(self, stms, ret)\
      if ret then\
        error(\"deprecated stms call, use transformer\")\
      end\
      local current_stms, current_stm_i\
      current_stms, current_stm_i = self.current_stms, self.current_stm_i\
      self.current_stms = stms\
      for i = 1, #stms do\
        self.current_stm_i = i\
        self:stm(stms[i])\
      end\
      self.current_stms = current_stms\
      self.current_stm_i = current_stm_i\
      return nil\
    end,\
    splice = function(self, fn)\
      local lines = {\
        \"lines\",\
        self._lines\
      }\
      self._lines = Lines()\
      return self:stms(fn(lines))\
    end\
  }\
  _base_0.__index = _base_0\
  _class_0 = setmetatable({\
    __init = function(self, parent, header, footer)\
      self.parent, self.header, self.footer = parent, header, footer\
      self._lines = Lines()\
      self._names = { }\
      self._state = { }\
      self._listeners = { }\
      do\
        self.transform = {\
          value = transform.Value:bind(self),\
          statement = transform.Statement:bind(self)\
        }\
      end\
      if self.parent then\
        self.root = self.parent.root\
        self.indent = self.parent.indent + 1\
        setmetatable(self._state, {\
          __index = self.parent._state\
        })\
        return setmetatable(self._listeners, {\
          __index = self.parent._listeners\
        })\
      else\
        self.indent = 0\
      end\
    end,\
    __base = _base_0,\
    __name = \"Block\"\
  }, {\
    __index = _base_0,\
    __call = function(cls, ...)\
      local _self_0 = setmetatable({}, _base_0)\
      cls.__init(_self_0, ...)\
      return _self_0\
    end\
  })\
  _base_0.__class = _class_0\
  Block = _class_0\
end\
do\
  local _class_0\
  local _parent_0 = Block\
  local _base_0 = {\
    __tostring = function(self)\
      return \"RootBlock<>\"\
    end,\
    root_stms = function(self, stms)\
      if not (self.options.implicitly_return_root == false) then\
        stms = transform.Statement.transformers.root_stms(self, stms)\
      end\
      return self:stms(stms)\
    end,\
    render = function(self)\
      local buffer = self._lines:flatten()\
      if buffer[#buffer] == \"\\n\" then\
        buffer[#buffer] = nil\
      end\
      return table.concat(buffer)\
    end\
  }\
  _base_0.__index = _base_0\
  setmetatable(_base_0, _parent_0.__base)\
  _class_0 = setmetatable({\
    __init = function(self, options)\
      self.options = options\
      self.root = self\
      return _class_0.__parent.__init(self)\
    end,\
    __base = _base_0,\
    __name = \"RootBlock\",\
    __parent = _parent_0\
  }, {\
    __index = function(cls, name)\
      local val = rawget(_base_0, name)\
      if val == nil then\
        local parent = rawget(cls, \"__parent\")\
        if parent then\
          return parent[name]\
        end\
      else\
        return val\
      end\
    end,\
    __call = function(cls, ...)\
      local _self_0 = setmetatable({}, _base_0)\
      cls.__init(_self_0, ...)\
      return _self_0\
    end\
  })\
  _base_0.__class = _class_0\
  if _parent_0.__inherited then\
    _parent_0.__inherited(_parent_0, _class_0)\
  end\
  RootBlock = _class_0\
end\
local format_error\
format_error = function(msg, pos, file_str)\
  local line_message\
  if pos then\
    local line = pos_to_line(file_str, pos)\
    local line_str\
    line_str, line = get_closest_line(file_str, line)\
    line_str = line_str or \"\"\
    line_message = (\" [%d] >>    %s\"):format(line, trim(line_str))\
  end\
  return concat({\
    \"Compile error: \" .. msg,\
    line_message\
  }, \"\\n\")\
end\
local value\
value = function(value)\
  local out = nil\
  do\
    local _with_0 = RootBlock()\
    _with_0:add(_with_0:value(value))\
    out = _with_0:render()\
  end\
  return out\
end\
local tree\
tree = function(tree, options)\
  if options == nil then\
    options = { }\
  end\
  assert(tree, \"missing tree\")\
  local scope = (options.scope or RootBlock)(options)\
  local runner = coroutine.create(function()\
    return scope:root_stms(tree)\
  end)\
  local success, err = coroutine.resume(runner)\
  if not (success) then\
    local error_msg, error_pos\
    if type(err) == \"table\" then\
      local _exp_0 = err[1]\
      if \"user-error\" == _exp_0 or \"compile-error\" == _exp_0 then\
        error_msg, error_pos = unpack(err, 2)\
      else\
        error_msg, error_pos = error(\"Unknown error thrown\", util.dump(error_msg))\
      end\
    else\
      error_msg, error_pos = concat({\
        err,\
        debug.traceback(runner)\
      }, \"\\n\")\
    end\
    return nil, error_msg, error_pos or scope.last_pos\
  end\
  local lua_code = scope:render()\
  local posmap = scope._lines:flatten_posmap()\
  return lua_code, posmap\
end\
do\
  local data = require(\"moonscript.data\")\
  for name, cls in pairs({\
    Line = Line,\
    Lines = Lines,\
    DelayedLine = DelayedLine\
  }) do\
    data[name] = cls\
  end\
end\
return {\
  tree = tree,\
  value = value,\
  format_error = format_error,\
  Block = Block,\
  RootBlock = RootBlock\
}\
"
, '@'.."/usr/share/lua/5.3/moonscript/compile.lua" ) )

package.preload[ "moonscript.transform.destructure" ] = assert( (loadstring or load)(
"local ntype, mtype, build\
do\
  local _obj_0 = require(\"moonscript.types\")\
  ntype, mtype, build = _obj_0.ntype, _obj_0.mtype, _obj_0.build\
end\
local NameProxy\
NameProxy = require(\"moonscript.transform.names\").NameProxy\
local insert\
insert = table.insert\
local unpack\
unpack = require(\"moonscript.util\").unpack\
local user_error\
user_error = require(\"moonscript.errors\").user_error\
local join\
join = function(...)\
  do\
    local out = { }\
    local i = 1\
    local _list_0 = {\
      ...\
    }\
    for _index_0 = 1, #_list_0 do\
      local tbl = _list_0[_index_0]\
      for _index_1 = 1, #tbl do\
        local v = tbl[_index_1]\
        out[i] = v\
        i = i + 1\
      end\
    end\
    return out\
  end\
end\
local has_destructure\
has_destructure = function(names)\
  for _index_0 = 1, #names do\
    local n = names[_index_0]\
    if ntype(n) == \"table\" then\
      return true\
    end\
  end\
  return false\
end\
local extract_assign_names\
extract_assign_names = function(name, accum, prefix)\
  if accum == nil then\
    accum = { }\
  end\
  if prefix == nil then\
    prefix = { }\
  end\
  local i = 1\
  local _list_0 = name[2]\
  for _index_0 = 1, #_list_0 do\
    local tuple = _list_0[_index_0]\
    local value, suffix\
    if #tuple == 1 then\
      local s = {\
        \"index\",\
        {\
          \"number\",\
          i\
        }\
      }\
      i = i + 1\
      value, suffix = tuple[1], s\
    else\
      local key = tuple[1]\
      local s\
      if ntype(key) == \"key_literal\" then\
        local key_name = key[2]\
        if ntype(key_name) == \"colon\" then\
          s = key_name\
        else\
          s = {\
            \"dot\",\
            key_name\
          }\
        end\
      else\
        s = {\
          \"index\",\
          key\
        }\
      end\
      value, suffix = tuple[2], s\
    end\
    suffix = join(prefix, {\
      suffix\
    })\
    local _exp_0 = ntype(value)\
    if \"value\" == _exp_0 or \"ref\" == _exp_0 or \"chain\" == _exp_0 or \"self\" == _exp_0 then\
      insert(accum, {\
        value,\
        suffix\
      })\
    elseif \"table\" == _exp_0 then\
      extract_assign_names(value, accum, suffix)\
    else\
      user_error(\"Can't destructure value of type: \" .. tostring(ntype(value)))\
    end\
  end\
  return accum\
end\
local build_assign\
build_assign = function(scope, destruct_literal, receiver)\
  local extracted_names = extract_assign_names(destruct_literal)\
  local names = { }\
  local values = { }\
  local inner = {\
    \"assign\",\
    names,\
    values\
  }\
  local obj\
  if scope:is_local(receiver) or #extracted_names == 1 then\
    obj = receiver\
  else\
    do\
      obj = NameProxy(\"obj\")\
      inner = build[\"do\"]({\
        build.assign_one(obj, receiver),\
        {\
          \"assign\",\
          names,\
          values\
        }\
      })\
      obj = obj\
    end\
  end\
  for _index_0 = 1, #extracted_names do\
    local tuple = extracted_names[_index_0]\
    insert(names, tuple[1])\
    local chain\
    if obj then\
      chain = NameProxy.chain(obj, unpack(tuple[2]))\
    else\
      chain = \"nil\"\
    end\
    insert(values, chain)\
  end\
  return build.group({\
    {\
      \"declare\",\
      names\
    },\
    inner\
  })\
end\
local split_assign\
split_assign = function(scope, assign)\
  local names, values = unpack(assign, 2)\
  local g = { }\
  local total_names = #names\
  local total_values = #values\
  local start = 1\
  for i, n in ipairs(names) do\
    if ntype(n) == \"table\" then\
      if i > start then\
        local stop = i - 1\
        insert(g, {\
          \"assign\",\
          (function()\
            local _accum_0 = { }\
            local _len_0 = 1\
            for i = start, stop do\
              _accum_0[_len_0] = names[i]\
              _len_0 = _len_0 + 1\
            end\
            return _accum_0\
          end)(),\
          (function()\
            local _accum_0 = { }\
            local _len_0 = 1\
            for i = start, stop do\
              _accum_0[_len_0] = values[i]\
              _len_0 = _len_0 + 1\
            end\
            return _accum_0\
          end)()\
        })\
      end\
      insert(g, build_assign(scope, n, values[i]))\
      start = i + 1\
    end\
  end\
  if total_names >= start or total_values >= start then\
    local name_slice\
    if total_names < start then\
      name_slice = {\
        \"_\"\
      }\
    else\
      do\
        local _accum_0 = { }\
        local _len_0 = 1\
        for i = start, total_names do\
          _accum_0[_len_0] = names[i]\
          _len_0 = _len_0 + 1\
        end\
        name_slice = _accum_0\
      end\
    end\
    local value_slice\
    if total_values < start then\
      value_slice = {\
        \"nil\"\
      }\
    else\
      do\
        local _accum_0 = { }\
        local _len_0 = 1\
        for i = start, total_values do\
          _accum_0[_len_0] = values[i]\
          _len_0 = _len_0 + 1\
        end\
        value_slice = _accum_0\
      end\
    end\
    insert(g, {\
      \"assign\",\
      name_slice,\
      value_slice\
    })\
  end\
  return build.group(g)\
end\
return {\
  has_destructure = has_destructure,\
  split_assign = split_assign,\
  build_assign = build_assign,\
  extract_assign_names = extract_assign_names\
}\
"
, '@'.."/usr/share/lua/5.3/moonscript/transform/destructure.lua" ) )

package.preload[ "moonscript.base" ] = assert( (loadstring or load)(
"local compile = require(\"moonscript.compile\")\
local parse = require(\"moonscript.parse\")\
local concat, insert, remove\
do\
  local _obj_0 = table\
  concat, insert, remove = _obj_0.concat, _obj_0.insert, _obj_0.remove\
end\
local split, dump, get_options, unpack\
do\
  local _obj_0 = require(\"moonscript.util\")\
  split, dump, get_options, unpack = _obj_0.split, _obj_0.dump, _obj_0.get_options, _obj_0.unpack\
end\
local lua = {\
  loadstring = loadstring,\
  load = load\
}\
local dirsep, line_tables, create_moonpath, to_lua, moon_loader, loadstring, loadfile, dofile, insert_loader, remove_loader\
dirsep = \"/\"\
line_tables = require(\"moonscript.line_tables\")\
create_moonpath = function(package_path)\
  local moonpaths\
  do\
    local _accum_0 = { }\
    local _len_0 = 1\
    local _list_0 = split(package_path, \";\")\
    for _index_0 = 1, #_list_0 do\
      local _continue_0 = false\
      repeat\
        local path = _list_0[_index_0]\
        local prefix = path:match(\"^(.-)%.lua$\")\
        if not (prefix) then\
          _continue_0 = true\
          break\
        end\
        local _value_0 = prefix .. \".moon\"\
        _accum_0[_len_0] = _value_0\
        _len_0 = _len_0 + 1\
        _continue_0 = true\
      until true\
      if not _continue_0 then\
        break\
      end\
    end\
    moonpaths = _accum_0\
  end\
  return concat(moonpaths, \";\")\
end\
to_lua = function(text, options)\
  if options == nil then\
    options = { }\
  end\
  if \"string\" ~= type(text) then\
    local t = type(text)\
    return nil, \"expecting string (got \" .. t .. \")\"\
  end\
  local tree, err = parse.string(text)\
  if not tree then\
    return nil, err\
  end\
  local code, ltable, pos = compile.tree(tree, options)\
  if not code then\
    return nil, compile.format_error(ltable, pos, text)\
  end\
  return code, ltable\
end\
moon_loader = function(name)\
  local name_path = name:gsub(\"%.\", dirsep)\
  local file, file_path\
  for path in package.moonpath:gmatch(\"[^;]+\") do\
    file_path = path:gsub(\"?\", name_path)\
    file = io.open(file_path)\
    if file then\
      break\
    end\
  end\
  if file then\
    local text = file:read(\"*a\")\
    file:close()\
    local res, err = loadstring(text, \"@\" .. tostring(file_path))\
    if not res then\
      error(file_path .. \": \" .. err)\
    end\
    return res\
  end\
  return nil, \"Could not find moon file\"\
end\
loadstring = function(...)\
  local options, str, chunk_name, mode, env = get_options(...)\
  chunk_name = chunk_name or \"=(moonscript.loadstring)\"\
  local code, ltable_or_err = to_lua(str, options)\
  if not (code) then\
    return nil, ltable_or_err\
  end\
  if chunk_name then\
    line_tables[chunk_name] = ltable_or_err\
  end\
  return (lua.loadstring or lua.load)(code, chunk_name, unpack({\
    mode,\
    env\
  }))\
end\
loadfile = function(fname, ...)\
  local file, err = io.open(fname)\
  if not (file) then\
    return nil, err\
  end\
  local text = assert(file:read(\"*a\"))\
  file:close()\
  return loadstring(text, \"@\" .. tostring(fname), ...)\
end\
dofile = function(...)\
  local f = assert(loadfile(...))\
  return f()\
end\
insert_loader = function(pos)\
  if pos == nil then\
    pos = 2\
  end\
  if not package.moonpath then\
    package.moonpath = create_moonpath(package.path)\
  end\
  local loaders = package.loaders or package.searchers\
  for _index_0 = 1, #loaders do\
    local loader = loaders[_index_0]\
    if loader == moon_loader then\
      return false\
    end\
  end\
  insert(loaders, pos, moon_loader)\
  return true\
end\
remove_loader = function()\
  local loaders = package.loaders or package.searchers\
  for i, loader in ipairs(loaders) do\
    if loader == moon_loader then\
      remove(loaders, i)\
      return true\
    end\
  end\
  return false\
end\
return {\
  _NAME = \"moonscript\",\
  insert_loader = insert_loader,\
  remove_loader = remove_loader,\
  to_lua = to_lua,\
  moon_loader = moon_loader,\
  dirsep = dirsep,\
  dofile = dofile,\
  loadfile = loadfile,\
  loadstring = loadstring,\
  create_moonpath = create_moonpath\
}\
"
, '@'.."/usr/share/lua/5.3/moonscript/base.lua" ) )

package.preload[ "moonscript.transform.statement" ] = assert( (loadstring or load)(
"local Transformer\
Transformer = require(\"moonscript.transform.transformer\").Transformer\
local NameProxy, LocalName, is_name_proxy\
do\
  local _obj_0 = require(\"moonscript.transform.names\")\
  NameProxy, LocalName, is_name_proxy = _obj_0.NameProxy, _obj_0.LocalName, _obj_0.is_name_proxy\
end\
local Run, transform_last_stm, implicitly_return, last_stm\
do\
  local _obj_0 = require(\"moonscript.transform.statements\")\
  Run, transform_last_stm, implicitly_return, last_stm = _obj_0.Run, _obj_0.transform_last_stm, _obj_0.implicitly_return, _obj_0.last_stm\
end\
local types = require(\"moonscript.types\")\
local build, ntype, is_value, smart_node, value_is_singular, is_slice, NOOP\
build, ntype, is_value, smart_node, value_is_singular, is_slice, NOOP = types.build, types.ntype, types.is_value, types.smart_node, types.value_is_singular, types.is_slice, types.NOOP\
local insert\
insert = table.insert\
local destructure = require(\"moonscript.transform.destructure\")\
local construct_comprehension\
construct_comprehension = require(\"moonscript.transform.comprehension\").construct_comprehension\
local unpack\
unpack = require(\"moonscript.util\").unpack\
local with_continue_listener\
with_continue_listener = function(body)\
  local continue_name = nil\
  return {\
    Run(function(self)\
      return self:listen(\"continue\", function()\
        if not (continue_name) then\
          continue_name = NameProxy(\"continue\")\
          self:put_name(continue_name)\
        end\
        return continue_name\
      end)\
    end),\
    build.group(body),\
    Run(function(self)\
      if not (continue_name) then\
        return \
      end\
      local last = last_stm(body)\
      local enclose_lines = types.terminating[last and ntype(last)]\
      self:put_name(continue_name, nil)\
      return self:splice(function(lines)\
        if enclose_lines then\
          lines = {\
            \"do\",\
            {\
              lines\
            }\
          }\
        end\
        return {\
          {\
            \"assign\",\
            {\
              continue_name\
            },\
            {\
              \"false\"\
            }\
          },\
          {\
            \"repeat\",\
            \"true\",\
            {\
              lines,\
              {\
                \"assign\",\
                {\
                  continue_name\
                },\
                {\
                  \"true\"\
                }\
              }\
            }\
          },\
          {\
            \"if\",\
            {\
              \"not\",\
              continue_name\
            },\
            {\
              {\
                \"break\"\
              }\
            }\
          }\
        }\
      end)\
    end)\
  }\
end\
local extract_declarations\
extract_declarations = function(self, body, start, out)\
  if body == nil then\
    body = self.current_stms\
  end\
  if start == nil then\
    start = self.current_stm_i + 1\
  end\
  if out == nil then\
    out = { }\
  end\
  for i = start, #body do\
    local _continue_0 = false\
    repeat\
      local stm = body[i]\
      if stm == nil then\
        _continue_0 = true\
        break\
      end\
      stm = self.transform.statement(stm)\
      body[i] = stm\
      local _exp_0 = stm[1]\
      if \"assign\" == _exp_0 or \"declare\" == _exp_0 then\
        local _list_0 = stm[2]\
        for _index_0 = 1, #_list_0 do\
          local name = _list_0[_index_0]\
          if ntype(name) == \"ref\" then\
            insert(out, name)\
          elseif type(name) == \"string\" then\
            insert(out, name)\
          end\
        end\
      elseif \"group\" == _exp_0 then\
        extract_declarations(self, stm[2], 1, out)\
      end\
      _continue_0 = true\
    until true\
    if not _continue_0 then\
      break\
    end\
  end\
  return out\
end\
local expand_elseif_assign\
expand_elseif_assign = function(ifstm)\
  for i = 4, #ifstm do\
    local case = ifstm[i]\
    if ntype(case) == \"elseif\" and ntype(case[2]) == \"assign\" then\
      local split = {\
        unpack(ifstm, 1, i - 1)\
      }\
      insert(split, {\
        \"else\",\
        {\
          {\
            \"if\",\
            case[2],\
            case[3],\
            unpack(ifstm, i + 1)\
          }\
        }\
      })\
      return split\
    end\
  end\
  return ifstm\
end\
return Transformer({\
  transform = function(self, tuple)\
    local _, node, fn\
    _, node, fn = tuple[1], tuple[2], tuple[3]\
    return fn(node)\
  end,\
  root_stms = function(self, body)\
    return transform_last_stm(body, implicitly_return(self))\
  end,\
  [\"return\"] = function(self, node)\
    local ret_val = node[2]\
    local ret_val_type = ntype(ret_val)\
    if ret_val_type == \"explist\" and #ret_val == 2 then\
      ret_val = ret_val[2]\
      ret_val_type = ntype(ret_val)\
    end\
    if types.cascading[ret_val_type] then\
      return implicitly_return(self)(ret_val)\
    end\
    if ret_val_type == \"chain\" or ret_val_type == \"comprehension\" or ret_val_type == \"tblcomprehension\" then\
      local Value = require(\"moonscript.transform.value\")\
      ret_val = Value:transform_once(self, ret_val)\
      if ntype(ret_val) == \"block_exp\" then\
        return build.group(transform_last_stm(ret_val[2], function(stm)\
          return {\
            \"return\",\
            stm\
          }\
        end))\
      end\
    end\
    node[2] = ret_val\
    return node\
  end,\
  declare_glob = function(self, node)\
    local names = extract_declarations(self)\
    if node[2] == \"^\" then\
      do\
        local _accum_0 = { }\
        local _len_0 = 1\
        for _index_0 = 1, #names do\
          local _continue_0 = false\
          repeat\
            local name = names[_index_0]\
            local str_name\
            if ntype(name) == \"ref\" then\
              str_name = name[2]\
            else\
              str_name = name\
            end\
            if not (str_name:match(\"^%u\")) then\
              _continue_0 = true\
              break\
            end\
            local _value_0 = name\
            _accum_0[_len_0] = _value_0\
            _len_0 = _len_0 + 1\
            _continue_0 = true\
          until true\
          if not _continue_0 then\
            break\
          end\
        end\
        names = _accum_0\
      end\
    end\
    return {\
      \"declare\",\
      names\
    }\
  end,\
  assign = function(self, node)\
    local names, values = unpack(node, 2)\
    local num_values = #values\
    local num_names = #values\
    if num_names == 1 and num_values == 1 then\
      local first_value = values[1]\
      local first_name = names[1]\
      local first_type = ntype(first_value)\
      if first_type == \"chain\" then\
        local Value = require(\"moonscript.transform.value\")\
        first_value = Value:transform_once(self, first_value)\
        first_type = ntype(first_value)\
      end\
      local _exp_0 = ntype(first_value)\
      if \"block_exp\" == _exp_0 then\
        local block_body = first_value[2]\
        local idx = #block_body\
        block_body[idx] = build.assign_one(first_name, block_body[idx])\
        return build.group({\
          {\
            \"declare\",\
            {\
              first_name\
            }\
          },\
          {\
            \"do\",\
            block_body\
          }\
        })\
      elseif \"comprehension\" == _exp_0 or \"tblcomprehension\" == _exp_0 or \"foreach\" == _exp_0 or \"for\" == _exp_0 or \"while\" == _exp_0 then\
        local Value = require(\"moonscript.transform.value\")\
        return build.assign_one(first_name, Value:transform_once(self, first_value))\
      else\
        values[1] = first_value\
      end\
    end\
    local transformed\
    if num_values == 1 then\
      local value = values[1]\
      local t = ntype(value)\
      if t == \"decorated\" then\
        value = self.transform.statement(value)\
        t = ntype(value)\
      end\
      if types.cascading[t] then\
        local ret\
        ret = function(stm)\
          if is_value(stm) then\
            return {\
              \"assign\",\
              names,\
              {\
                stm\
              }\
            }\
          else\
            return stm\
          end\
        end\
        transformed = build.group({\
          {\
            \"declare\",\
            names\
          },\
          self.transform.statement(value, ret, node)\
        })\
      end\
    end\
    node = transformed or node\
    if destructure.has_destructure(names) then\
      return destructure.split_assign(self, node)\
    end\
    return node\
  end,\
  continue = function(self, node)\
    local continue_name = self:send(\"continue\")\
    if not (continue_name) then\
      error(\"continue must be inside of a loop\")\
    end\
    return build.group({\
      build.assign_one(continue_name, \"true\"),\
      {\
        \"break\"\
      }\
    })\
  end,\
  export = function(self, node)\
    if #node > 2 then\
      if node[2] == \"class\" then\
        local cls = smart_node(node[3])\
        return build.group({\
          {\
            \"export\",\
            {\
              cls.name\
            }\
          },\
          cls\
        })\
      else\
        return build.group({\
          {\
            \"export\",\
            node[2]\
          },\
          build.assign({\
            names = node[2],\
            values = node[3]\
          })\
        })\
      end\
    else\
      return nil\
    end\
  end,\
  update = function(self, node)\
    local name, op, exp = unpack(node, 2)\
    local op_final = op:match(\"^(.+)=$\")\
    if not op_final then\
      error(\"Unknown op: \" .. op)\
    end\
    if not (value_is_singular(exp)) then\
      exp = {\
        \"parens\",\
        exp\
      }\
    end\
    return build.assign_one(name, {\
      \"exp\",\
      name,\
      op_final,\
      exp\
    })\
  end,\
  import = function(self, node)\
    local names, source = unpack(node, 2)\
    local table_values\
    do\
      local _accum_0 = { }\
      local _len_0 = 1\
      for _index_0 = 1, #names do\
        local name = names[_index_0]\
        local dest_name\
        if ntype(name) == \"colon\" then\
          dest_name = name[2]\
        else\
          dest_name = name\
        end\
        local _value_0 = {\
          {\
            \"key_literal\",\
            name\
          },\
          dest_name\
        }\
        _accum_0[_len_0] = _value_0\
        _len_0 = _len_0 + 1\
      end\
      table_values = _accum_0\
    end\
    local dest = {\
      \"table\",\
      table_values\
    }\
    return {\
      \"assign\",\
      {\
        dest\
      },\
      {\
        source\
      },\
      [-1] = node[-1]\
    }\
  end,\
  comprehension = function(self, node, action)\
    local exp, clauses = unpack(node, 2)\
    action = action or function(exp)\
      return {\
        exp\
      }\
    end\
    return construct_comprehension(action(exp), clauses)\
  end,\
  [\"do\"] = function(self, node, ret)\
    if ret then\
      node[2] = transform_last_stm(node[2], ret)\
    end\
    return node\
  end,\
  decorated = function(self, node)\
    local stm, dec = unpack(node, 2)\
    local wrapped\
    local _exp_0 = dec[1]\
    if \"if\" == _exp_0 then\
      local cond, fail = unpack(dec, 2)\
      if fail then\
        fail = {\
          \"else\",\
          {\
            fail\
          }\
        }\
      end\
      wrapped = {\
        \"if\",\
        cond,\
        {\
          stm\
        },\
        fail\
      }\
    elseif \"unless\" == _exp_0 then\
      wrapped = {\
        \"unless\",\
        dec[2],\
        {\
          stm\
        }\
      }\
    elseif \"comprehension\" == _exp_0 then\
      wrapped = {\
        \"comprehension\",\
        stm,\
        dec[2]\
      }\
    else\
      wrapped = error(\"Unknown decorator \" .. dec[1])\
    end\
    if ntype(stm) == \"assign\" then\
      wrapped = build.group({\
        build.declare({\
          names = (function()\
            local _accum_0 = { }\
            local _len_0 = 1\
            local _list_0 = stm[2]\
            for _index_0 = 1, #_list_0 do\
              local name = _list_0[_index_0]\
              if ntype(name) == \"ref\" then\
                _accum_0[_len_0] = name\
                _len_0 = _len_0 + 1\
              end\
            end\
            return _accum_0\
          end)()\
        }),\
        wrapped\
      })\
    end\
    return wrapped\
  end,\
  unless = function(self, node)\
    local clause = node[2]\
    if ntype(clause) == \"assign\" then\
      if destructure.has_destructure(clause[2]) then\
        error(\"destructure not allowed in unless assignment\")\
      end\
      return build[\"do\"]({\
        clause,\
        {\
          \"if\",\
          {\
            \"not\",\
            clause[2][1]\
          },\
          unpack(node, 3)\
        }\
      })\
    else\
      return {\
        \"if\",\
        {\
          \"not\",\
          {\
            \"parens\",\
            clause\
          }\
        },\
        unpack(node, 3)\
      }\
    end\
  end,\
  [\"if\"] = function(self, node, ret)\
    if ntype(node[2]) == \"assign\" then\
      local assign, body = unpack(node, 2)\
      if destructure.has_destructure(assign[2]) then\
        local name = NameProxy(\"des\")\
        body = {\
          destructure.build_assign(self, assign[2][1], name),\
          build.group(node[3])\
        }\
        return build[\"do\"]({\
          build.assign_one(name, assign[3][1]),\
          {\
            \"if\",\
            name,\
            body,\
            unpack(node, 4)\
          }\
        })\
      else\
        local name = assign[2][1]\
        return build[\"do\"]({\
          assign,\
          {\
            \"if\",\
            name,\
            unpack(node, 3)\
          }\
        })\
      end\
    end\
    node = expand_elseif_assign(node)\
    if ret then\
      smart_node(node)\
      node['then'] = transform_last_stm(node['then'], ret)\
      for i = 4, #node do\
        local case = node[i]\
        local body_idx = #node[i]\
        case[body_idx] = transform_last_stm(case[body_idx], ret)\
      end\
    end\
    return node\
  end,\
  with = function(self, node, ret)\
    local exp, block = unpack(node, 2)\
    local copy_scope = true\
    local scope_name, named_assign\
    do\
      local last = last_stm(block)\
      if last then\
        if types.terminating[ntype(last)] then\
          ret = false\
        end\
      end\
    end\
    if ntype(exp) == \"assign\" then\
      local names, values = unpack(exp, 2)\
      local first_name = names[1]\
      if ntype(first_name) == \"ref\" then\
        scope_name = first_name\
        named_assign = exp\
        exp = values[1]\
        copy_scope = false\
      else\
        scope_name = NameProxy(\"with\")\
        exp = values[1]\
        values[1] = scope_name\
        named_assign = {\
          \"assign\",\
          names,\
          values\
        }\
      end\
    elseif self:is_local(exp) then\
      scope_name = exp\
      copy_scope = false\
    end\
    scope_name = scope_name or NameProxy(\"with\")\
    local out = build[\"do\"]({\
      copy_scope and build.assign_one(scope_name, exp) or NOOP,\
      named_assign or NOOP,\
      Run(function(self)\
        return self:set(\"scope_var\", scope_name)\
      end),\
      unpack(block)\
    })\
    if ret then\
      table.insert(out[2], ret(scope_name))\
    end\
    return out\
  end,\
  foreach = function(self, node, _)\
    smart_node(node)\
    local source = unpack(node.iter)\
    local destructures = { }\
    do\
      local _accum_0 = { }\
      local _len_0 = 1\
      for i, name in ipairs(node.names) do\
        if ntype(name) == \"table\" then\
          do\
            local proxy = NameProxy(\"des\")\
            insert(destructures, destructure.build_assign(self, name, proxy))\
            _accum_0[_len_0] = proxy\
          end\
        else\
          _accum_0[_len_0] = name\
        end\
        _len_0 = _len_0 + 1\
      end\
      node.names = _accum_0\
    end\
    if next(destructures) then\
      insert(destructures, build.group(node.body))\
      node.body = destructures\
    end\
    if ntype(source) == \"unpack\" then\
      local list = source[2]\
      local index_name = NameProxy(\"index\")\
      local list_name = self:is_local(list) and list or NameProxy(\"list\")\
      local slice_var = nil\
      local bounds\
      if is_slice(list) then\
        local slice = list[#list]\
        table.remove(list)\
        table.remove(slice, 1)\
        if self:is_local(list) then\
          list_name = list\
        end\
        if slice[2] and slice[2] ~= \"\" then\
          local max_tmp_name = NameProxy(\"max\")\
          slice_var = build.assign_one(max_tmp_name, slice[2])\
          slice[2] = {\
            \"exp\",\
            max_tmp_name,\
            \"<\",\
            0,\
            \"and\",\
            {\
              \"length\",\
              list_name\
            },\
            \"+\",\
            max_tmp_name,\
            \"or\",\
            max_tmp_name\
          }\
        else\
          slice[2] = {\
            \"length\",\
            list_name\
          }\
        end\
        bounds = slice\
      else\
        bounds = {\
          1,\
          {\
            \"length\",\
            list_name\
          }\
        }\
      end\
      local names\
      do\
        local _accum_0 = { }\
        local _len_0 = 1\
        local _list_0 = node.names\
        for _index_0 = 1, #_list_0 do\
          local n = _list_0[_index_0]\
          _accum_0[_len_0] = is_name_proxy(n) and n or LocalName(n) or n\
          _len_0 = _len_0 + 1\
        end\
        names = _accum_0\
      end\
      return build.group({\
        list_name ~= list and build.assign_one(list_name, list) or NOOP,\
        slice_var or NOOP,\
        build[\"for\"]({\
          name = index_name,\
          bounds = bounds,\
          body = {\
            {\
              \"assign\",\
              names,\
              {\
                NameProxy.index(list_name, index_name)\
              }\
            },\
            build.group(node.body)\
          }\
        })\
      })\
    end\
    node.body = with_continue_listener(node.body)\
  end,\
  [\"while\"] = function(self, node)\
    smart_node(node)\
    node.body = with_continue_listener(node.body)\
  end,\
  [\"for\"] = function(self, node)\
    smart_node(node)\
    node.body = with_continue_listener(node.body)\
  end,\
  switch = function(self, node, ret)\
    local exp, conds = unpack(node, 2)\
    local exp_name = NameProxy(\"exp\")\
    local convert_cond\
    convert_cond = function(cond)\
      local t, case_exps, body = unpack(cond)\
      local out = { }\
      insert(out, t == \"case\" and \"elseif\" or \"else\")\
      if t ~= \"else\" then\
        local cond_exp = { }\
        for i, case in ipairs(case_exps) do\
          if i == 1 then\
            insert(cond_exp, \"exp\")\
          else\
            insert(cond_exp, \"or\")\
          end\
          if not (value_is_singular(case)) then\
            case = {\
              \"parens\",\
              case\
            }\
          end\
          insert(cond_exp, {\
            \"exp\",\
            case,\
            \"==\",\
            exp_name\
          })\
        end\
        insert(out, cond_exp)\
      else\
        body = case_exps\
      end\
      if ret then\
        body = transform_last_stm(body, ret)\
      end\
      insert(out, body)\
      return out\
    end\
    local first = true\
    local if_stm = {\
      \"if\"\
    }\
    for _index_0 = 1, #conds do\
      local cond = conds[_index_0]\
      local if_cond = convert_cond(cond)\
      if first then\
        first = false\
        insert(if_stm, if_cond[2])\
        insert(if_stm, if_cond[3])\
      else\
        insert(if_stm, if_cond)\
      end\
    end\
    return build.group({\
      build.assign_one(exp_name, exp),\
      if_stm\
    })\
  end,\
  class = require(\"moonscript.transform.class\")\
})\
"
, '@'.."/usr/share/lua/5.3/moonscript/transform/statement.lua" ) )

package.preload[ "moonscript.dump" ] = assert( (loadstring or load)(
"local flat_value\
flat_value = function(op, depth)\
  if depth == nil then\
    depth = 1\
  end\
  if type(op) == \"string\" then\
    return '\"' .. op .. '\"'\
  end\
  if type(op) ~= \"table\" then\
    return tostring(op)\
  end\
  local items\
  do\
    local _accum_0 = { }\
    local _len_0 = 1\
    for _index_0 = 1, #op do\
      local item = op[_index_0]\
      _accum_0[_len_0] = flat_value(item, depth + 1)\
      _len_0 = _len_0 + 1\
    end\
    items = _accum_0\
  end\
  local pos = op[-1]\
  return \"{\" .. (pos and \"[\" .. pos .. \"] \" or \"\") .. table.concat(items, \", \") .. \"}\"\
end\
local value\
value = function(op)\
  return flat_value(op)\
end\
local tree\
tree = function(block)\
  local _list_0 = block\
  for _index_0 = 1, #_list_0 do\
    local value = _list_0[_index_0]\
    print(flat_value(value))\
  end\
end\
return {\
  value = value,\
  tree = tree\
}\
"
, '@'.."/usr/share/lua/5.3/moonscript/dump.lua" ) )
