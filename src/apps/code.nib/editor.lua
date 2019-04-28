local NOM = require 'nibui.NOM'
local Widget = require 'nibui.Widget'
local Textarea = require 'nibui.Textarea'
local Text = require 'nibui.Text'
local Lexer = require 'Lexer'
local d = NOM.dynamic

local editor_margin = 1

local function read_file(file)
    --local f = assert(io.open(file, "rb"))
    --local content = f:read("*all")
    --f:close()
    return ""
end

local code = read_file('apps/code.nib/editor.lua')

local lexer = Lexer:new()
lexer:add_keyword('function')
lexer:add_keyword('end')
lexer:add_keyword('if')
lexer:add_keyword('else')
lexer:add_keyword('elseif')
lexer:add_keyword('then')
lexer:add_keyword('do')
lexer:add_keyword('local')
lexer:add_keyword('self')
lexer:add_keyword('require')
lexer:add_keyword('(')
lexer:add_keyword(')')
lexer:add_keyword('[')
lexer:add_keyword(']')
lexer:add_keyword('{')
lexer:add_keyword('}')
lexer:add_keyword('=')
lexer:add_keyword(':')
lexer:add_keyword(',')
lexer:add_keyword('.')
lexer:add_delimiters("'", "'")
lexer:add_identifier('alphanumeric')
lexer:compile()

local function code2fragments(code)
    local fragments = {}

    for c in code:gmatch '.' do
        for i=1,2 do
            lexer:consume(c)

            local matches = lexer:matches()

            if matches then
                for _, match in ipairs(matches) do
                    if match.name == 'alphanumeric' then
                        table.insert(fragments, Text:new(match.matched))
                    else
                        if #match.name > 1  then
                            if match.name == 'function' or match.name == 'local' or match.name == 'require' then
                                table.insert(fragments, Text:new(match.matched):set('color', 6))
                            else
                                table.insert(fragments, Text:new(match.matched):set('color', 10))
                            end
                        else
                            if match.name == '(' or match.name == ')' then
                                table.insert(fragments, Text:new(match.matched):set('color', 11))
                            else
                                table.insert(fragments, Text:new(match.matched):set('color', 9))
                            end
                        end
                    end
                end
            end

            if not lexer:backtracked() then
                break
            end
        end

        if c == ' ' then
            table.insert(fragments, Text:new(' '))
        end

        if c == '\n' then
            table.insert(fragments, false)
        end
    end

    return fragments
end

return {
    w = d'-'(d'^' 'w', 2*editor_margin),
    h = d'-'(d'^' 'h', 2*editor_margin),
    x = d'+'(d'left', editor_margin),
    y = d'+'(d'top', editor_margin),
    background = 1,

    draw = function (self)
        if not self.textarea then
            self.textarea = Textarea:new(self.x, self.y, self.w, self.h)

            local fragments = code2fragments(code)

            for _, frag in ipairs(fragments) do
                if frag then
                    self.textarea:add(frag)
                else
                    self.textarea:newline()
                end
            end
        end

        Widget.draw(self)

        clip(self.x, self.y, self.w, self.h)
        self.textarea:draw()
    end,

    onmove = function (self, event)
        if event.drag then
            self.textarea:scroll(event.y-self.init_y)
            self.parent:set_dirty()
        end

        self.init_y = event.y
    end
}
