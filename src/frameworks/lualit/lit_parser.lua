local parser = {}

-- Quick and dirty way to transform a lualit string to lua string.
-- We retain the same number of lines after replacing.
-- This aids with debugging, since lualit and lua file are 1:1, program
-- errors will show correct line numbers.
function parser.parse_to_lua(input_string)
  local output_string = input_string
    -- Comment out any non-space text at beginning of lua string
    :gsub("^(%S)", "-- %1", 1)
    -- Comment any non-space text that occurs on a new line
    :gsub("\n(%S)", "\n-- %1")
    -- "Outdent" any indented code.
    :gsub("\n    ", "\n")
  return output_string
end

return parser