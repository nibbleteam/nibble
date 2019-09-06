local StateMachine = {
    Finish = { finish = true, transitions = {}, matched = '' }
}

function StateMachine:new()
    local o = {
        state = StateMachine.Finish,
        initial = StateMachine.Finish,
    }

    instanceof(o, StateMachine)

    return o
end

function StateMachine:compile()
    self.state = { self.state }
    self.initial = { self.initial }
end

function StateMachine:reset()
    self.state = self.initial
end

function StateMachine:finished()
    for _, state in ipairs(self.state) do
        if state.finish then
            return true
        end
    end

    return false
end

function StateMachine:backtracked()
    for _, state in ipairs(self.state) do
        if not state.backtrack then
            return false
        end
    end

    return true
end

function StateMachine:consume(char)
    local states = {}

    for _, state in ipairs(self.state) do
        if not state.finish then
            for tr_char, tr_state in pairs(state.transitions) do
                local state = copy(state)

                if tr_char == 'alphanumeric' and (char:match('%W') == nil or char == '_') then
                    if tr_state ~= 'stay' then
                        tr_state.matched = state.matched .. char
                        insert(states, tr_state)
                    else
                        state.matched = (state.matched or '') .. char
                        insert(states, state)
                    end
                end

                if tr_char == 'nonalphanumeric' and (char:match('%W') ~= nil and char ~= '_') then
                    if tr_state ~= 'stay' then
                        if tr_state.backtrack then
                            tr_state.matched = state.matched
                            insert(states, tr_state)
                        else
                            tr_state.matched = state.matched .. char
                            insert(states, state)
                        end
                    end
                end

                if tr_char == 'any' then
                    if tr_state ~= 'stay' then
                        if tr_state.backtrack then
                            tr_state.matched = state.matched
                            insert(states, tr_state)
                        else
                            tr_state.matched = state.matched .. char
                            insert(states, state)
                        end
                    else
                        state.matched = state.matched .. char
                        insert(states, state)
                    end
                end

                if tr_char == char then
                    if tr_state ~= 'stay' then
                        tr_state.matched = state.matched .. char
                        insert(states, tr_state)
                    else
                        state.matched = state.matched .. char
                        insert(states, state)
                    end
                end
            end
        end
    end

    if #states > 0 then
        self.state = states
    else
        self:reset()
    end
end

local function merge(a, b)
    a = a or { transitions = {} }
    b = b or { transitions = {} }

    for b_char, b_state in pairs(b.transitions) do
        local a_state = a.transitions[b_char]

        if a_state == nil then
            a.transitions[b_char] = b_state

            a.finish = nil
        else
            a.transitions[b_char] = merge(a_state, b_state)

            a.finish = nil
        end
    end

    return a
end

function StateMachine:merge(other)
    self.state = merge(self.state, other.state)
end

function StateMachine:from_str(str, priority)
    local state = {
        finish = true,
        name = str,
        transitions = {},
    }

    for s=#str,1,-1 do
        local char = str:sub(s,s)

        state = {
            transitions = {
                [char] = state
            },
        }
    end

    state.matched = ''

    local o = {
        state = state,
        initial = state,
    }

    instanceof(o, StateMachine)

    return o
end

function StateMachine:from_delimiters(begin, finish, priority)
    local o = {
        state = {
            transitions = {
                [begin] = {
                    transitions = {
                        [finish] = {
                            finish = true,
                            transitions = {},
                            name = begin..', '..finish
                        },
                        any = 'stay'
                    }
                }
            },
            matched = ''
        }
    }

    o.initial = o.state

    instanceof(o, StateMachine)

    return o
end

function StateMachine:from_characters(kind, priority)
    local o = {
        state = {
            transitions = {
                [kind] = {
                    transitions = {
                        [kind] = 'stay',
                        nonalphanumeric = {
                            finish = true,
                            backtrack = true,
                            transitions = {},
                            name = kind
                        }
                    }
                }
            },
            matched = ''
        }
    }

    o.initial = o.state

    instanceof(o, StateMachine)

    return o
end

return StateMachine
