local NOM = require 'nibui.NOM'
--local Widget = require 'nibui.Widget'
--local Textarea = require 'nibui.Textarea'
--local Text = require 'nibui.Text'
--local Lexer = require 'Lexer'

local Editor = require 'Editor'

local editor_margin = 1

--local lexer = Lexer:new()
--lexer:add_keyword('function')
--lexer:add_keyword('end')
--lexer:add_keyword('if')
--lexer:add_keyword('else')
--lexer:add_keyword('elseif')
--lexer:add_keyword('then')
--lexer:add_keyword('do')
--lexer:add_keyword('local')
--lexer:add_keyword('self')
--lexer:add_keyword('require')
--lexer:add_keyword('(')
--lexer:add_keyword(')')
--lexer:add_keyword('[')
--lexer:add_keyword(']')
--lexer:add_keyword('{')
--lexer:add_keyword('}')
--lexer:add_keyword('=')
--lexer:add_keyword(':')
--lexer:add_keyword(',')
--lexer:add_keyword('.')
--lexer:add_keyword('+')
--lexer:add_keyword('-')
--lexer:add_keyword('/')
--lexer:add_keyword('*')
--lexer:add_keyword('+=')
--lexer:add_keyword('-=')
--lexer:add_keyword('/=')
--lexer:add_keyword('*=')
--lexer:add_delimiters("'", "'")
--lexer:add_delimiters('"', '"')
--lexer:add_identifier('alphanumeric')
--lexer:compile()

--local function code2fragments(code)
--    local fragments = {}
--
--    for c in code:gmatch '.' do
--        for i=1,2 do
--            lexer:consume(c)
--
--            local matches = lexer:matches()
--
--            if matches then
--                for _, match in ipairs(matches) do
--                    if match.name == 'alphanumeric' then
--                        insert(fragments, Text:new(match.matched))
--                    else
--                        if #match.name > 1  then
--                            if match.name == 'function' or match.name == 'local' or match.name == 'require' then
--                                insert(fragments, Text:new(match.matched):set('colormap', { [15] = 6 }))
--                            else
--                                insert(fragments, Text:new(match.matched):set('colormap', { [15] = 10 }))
--                            end
--                        else
--                            if match.name == '(' or match.name == ')' then
--                                insert(fragments, Text:new(match.matched):set('colormap', { [15] = 11 }))
--                            else
--                                insert(fragments, Text:new(match.matched):set('colormap', { [15] = 9 }))
--                            end
--                        end
--                    end
--                end
--            end
    --
--            if not lexer:backtracked() then
--                break
--            end
--        end
    --
--        if c == ' ' then
--            insert(fragments, Text:new(' '))
--        end
    --
--        if c == '\n' then
--            insert(fragments, false)
--        end
--    end
    --
--    return fragments
--end

function write_file(file, text)
    local f = io.open(file, "w")

    if f then
        f:write(text)
        f:close()

        return true
    end

    return nil
end

local init_y = 0

return {
    w = NOM.width-2*editor_margin,
    h = NOM.height-2*editor_margin,
    x = NOM.left+editor_margin,
    y = NOM.top+editor_margin,

    background = 1,

    draw = function (self)
        if not self.editor then
            self.editor = Editor:new(self.code)
        end

        clip(self.x, self.y, self.w, self.h)

        self.editor:draw(self.x, self.y, self.w, self.h)
    end,

    update = function(self)
        local input = read_keys()

        for i=1,#input do
            local char = input:sub(i, i)

            if char == "\08" then
                self.editor:remove_chars(-1)
            elseif char == "\13" then
                self.editor:insert_line()
            else
                self.editor:insert_chars(char)
            end

            write_file(self.filename, self.editor:text())
        end

        if button_press(RIGHT) then
            self.editor:move_by_chars(1)
        end

        if button_press(LEFT) then
            self.editor:move_by_chars(-1)
        end

        if button_press(DOWN) then
            self.editor:move_by_lines(1)
        end

        if button_press(UP) then
            self.editor:move_by_lines(-1)
        end

        if #input > 0 then
            self:set_dirty()
        end
    end,

    onmove = function (self, event)
        if event.drag then
            self.textarea:scroll(event.y-init_y)
            self.parent:set_dirty()
        end

        init_y = event.y
    end
}
