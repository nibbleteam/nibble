local Line = {}

local Lexer = require 'Lexer'

local keywords = {
  ["("] = 10,
  [":"] = 10,
  [")"] = 10,
  ["["] = 10,
  ["]"] = 10,
  ["+="] = 8,
  ["-="] = 8,
  ["*="] = 8,
  ["/="] = 8,
  ["~="] = 8,
  ["=="] = 8,
  [">="] = 8,
  ["<="] = 8,
  ["."] = 8,
  [">"] = 8,
  ["<"] = 8,
  ["="] = 6,
  ["*"] = 6,
  ["/"] = 6,
  ["-"] = 6,
  ["+"] = 6,
  [".."] = 6,
  [","] = 10,
  ["{"] = 10,
  ["}"] = 10,
  ["function"] = 6,
  ["in"] = 6,
  ["for"] = 6,
  ["repeat"] = 6,
  ["while"] = 6,
  ["end"] = 6,
  ["then"] = 6,
  ["break"] = 6,
  ["require"] = 6,
  ["local"] = 6,
  ["if"] = 6,
  ["else"] = 6,
  ["elseif"] = 6,
  ["do"] = 6,
  ["return"] = 6,
  ["not"] = 12,
  ["or"] = 12,
  ["and"] = 12,
  ["self"] = 9,
  ["true"] = 8,
  ["false"] = 8,

  ["nil"] = 9,
  ["', '"] = 14,
  ['", "'] = 14,
  ['--, \n'] = 7,
  ["alphanumeric"] = 15,
  ["numeric"] = 8,

  ["UP"] = 13,
  ["DOWN"] = 13,
  ["LEFT"] = 13,
  ["RIGHT"] = 13,
  ["BLACK"] = 2,
  ["WHITE"] = 14,
  ["RED"] = 6,
  ["BLUE"] = 8,

  ["print"] = 13,
  ["measure"] = 13,
  ["clear"] = 13,
  ["fill_circ"] = 13,
  ["circ"] = 13,
}

local lexer = Lexer:new()

lexer:add_delimiters('--', '\n')

lexer:add_delimiters('"', '"')
lexer:add_delimiters("'", "'")

for keyword, _ in pairs(keywords) do
  lexer:add_keyword(keyword)
end

lexer:add_identifier("numeric")
lexer:add_identifier("alphanumeric")

lexer:compile()

local function colored_spans(str)
  local spans = {}
  local i_end = 1

  str = str.."\n "

  lexer:reset()

  for c in str:gmatch "." do
    for i=1,2 do
      lexer:consume(c)

      local match = lexer:matches()

      if match then
          insert(spans, {
            name = match.name,
            i_start = i_end-#match.matched,
            i_end = i_end-1,
          })
      end

      if not lexer:backtracked() then
        break
      end
    end

    i_end += 1
  end

  return spans
end

function Line:new(content, prev, weight)
  return new(Line, {
               content = content or "",
               prev = prev,
               next = nil,
               weight = weight,
               spans = nil
  })
end

function Line:highlight()
  self.spans = colored_spans(self.content)
end

function Line:length()
  return #self.content
end

function Line:height()
  return 10
end

function Line:draw(x, y)
  if not self.spans then
    self:highlight()
  end

  print(self.content, x, y)
 
  for _, span in ipairs(self.spans) do
    local str = self.content:sub(span.i_start, span.i_end)

    swap_colors(15, keywords[span.name] or 15)
    swap_colors(7, math.max((keywords[span.name] or 15) - 8, 1))

    print(str, x+(span.i_start-1)*8, y)
  end

  swap_colors(15, 15)
  swap_colors(7, 7)
end

return Line



