local StateMachine = require 'StateMachine'
local Lexer = {}

function Lexer:new()
    local o = {
        machine = StateMachine:new(),
        last_priority = 0,
    }

    instanceof(o, Lexer)

    return o
end

function Lexer:compile()
    self.machine:compile()
end

function Lexer:backtracked()
    return self.machine:backtracked()
end

function Lexer:consume(c)
    if self.machine:finished() then
        self.machine:reset()
    end

    self.machine:consume(c)
end

function Lexer:matches()
    if self.machine:finished() then
        if #self.machine.state > 0 then
            sort(self.machine.state, function (a, b)
                            return a.priority < b.priority
            end)

            return self.machine.state[1]
        end
    end
end

function Lexer:add_keyword(keyword)
    self.machine:merge(StateMachine:from_str(keyword, self.last_priority))

    self.last_priority += 1
end

function Lexer:add_delimiters(begin, finish)
    self.machine:merge(StateMachine:from_delimiters(begin, finish, self.last_priority))

    self.last_priority += 1
end

function Lexer:add_identifier(kind)
    self.machine:merge(StateMachine:from_characters(kind, self.last_priority))

    self.last_priority += 1
end

function Lexer:finished()
    return self.machine:finished()
end

function Lexer:reset()
  self.machine:reset()
end

return Lexer

