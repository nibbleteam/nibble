local write = require 'tty.write'

return function(str, bg)
  write(str.."\n", bg)
end