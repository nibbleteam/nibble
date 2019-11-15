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
        if not state.finish then
            return false
        end
    end

    return true
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
                local state = state

                if tr_char == 'alphanumeric' and (char:match('%W') == nil or char == '_') then
                    if tr_state ~= 'stay' then
                        tr_state.matched = state.matched .. char
                        insert(states, tr_state)
                    else
                        state.matched = (state.matched or '') .. char
                        insert(states, state)
                    end
                end

                if tr_char == 'numeric' and char:match('%D') == nil then
                    if tr_state ~= 'stay' then
                        tr_state.matched = state.matched .. char
                        insert(states, tr_state)
                    else
                        state.matched = (state.matched or '') .. char
                        insert(states, state)
                    end
                end

                if tr_char == 'nonnumeric' and char:match('%D') ~= nil then
                    if tr_state ~= 'stay' then
                        if tr_state.backtrack then
                            tr_state.matched = state.matched
                            insert(states, tr_state)
                        else
                            state.matched = state.matched .. char
                            insert(states, state)
                        end
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

                if tr_char:sub(1, 1) == "^" then
                    if tr_char:sub(2, 2) ~= char then
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
        transitions = {
            any = {
                finish = true,
                name = str,
                backtrack = true,
                transitions = {},
                priority = priority,
            }
        }
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
    local function match_str_and_then(str, st)
        if #str > 0 then
            return match_str_and_then(str:sub(1, #str-1), {
                                   transitions = {
                                       [str:sub(#str, #str)] = st
                                   }
            })
        else
            st.matched = ""
            return st
        end
    end

    local o = {
        state = match_str_and_then(begin, {
            transitions = {
                [finish] = {
                    transitions = {
                        any = {
                            finish = true,
                            backtrack = true,
                            name = begin..', '..finish,
                            transitions = {},
                            priority = priority,
                        }
                    }
                },
                ['^'..finish] = 'stay'
            }
        }),
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
                        ["non"..kind] = {
                            finish = true,
                            backtrack = true,
                            transitions = {},
                            name = kind,
                            priority = priority
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

