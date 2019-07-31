local NOM = require 'nibui.NOM'
local Widget = require 'nibui.Widget'
local Textarea = require 'nibui.Textarea'
local Text = require 'nibui.Text'
local Lexer = require 'Lexer'

local editor_margin = 1

local function read_file(file)
    local f = assert(open(file))
    local content = f:read("*all")
    f:close()

    return content
end

local code = read_file('apps/'..env.params[2]..'.nib/main.lua')

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
lexer:add_delimiters('"', '"')
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
                        insert(fragments, Text:new(match.matched))
                    else
                        if #match.name > 1  then
                            if match.name == 'function' or match.name == 'local' or match.name == 'require' then
                                insert(fragments, Text:new(match.matched):set('colormap', { [15] = 6 }))
                            else
                                insert(fragments, Text:new(match.matched):set('colormap', { [15] = 10 }))
                            end
                        else
                            if match.name == '(' or match.name == ')' then
                                insert(fragments, Text:new(match.matched):set('colormap', { [15] = 11 }))
                            else
                                insert(fragments, Text:new(match.matched):set('colormap', { [15] = 9 }))
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
            insert(fragments, Text:new(' '))
        end

        if c == '\n' then
            insert(fragments, false)
        end
    end

    return fragments
end

return {
    w = NOM.width-2*editor_margin,
    h = NOM.height-2*editor_margin,
    x = NOM.left+editor_margin,
    y = NOM.top+editor_margin,

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

        fill_rect(self.textarea.cursor_x, self.textarea.cursor_y, 4, 8, 15)
    end,

    update = function(self)
        local input = read_keys()

        for i=1,#input do
            local char = input:sub(i, i)

            if char == "\08" then
                self.textarea:delete(1)
            elseif char == "\13" then
                self.textarea:newline()
            else
                self.textarea:add(Text:new(char))
            end
        end

        if #input > 0 then
            self:set_dirty()
        end
    end,

    onmove = function (self, event)
        if event.drag then
            self.textarea:scroll(event.y-self.init_y)
            self.parent:set_dirty()
        end

        self.init_y = event.y
    end
}
