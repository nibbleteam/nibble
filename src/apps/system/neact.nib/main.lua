require 'tty.write'

local NEACT_COMPONENT_TEMPLATE = "local NOM = require 'nibui.NOM'\nlocal $$ = Neact.Component:new()\n\nfunction $$:new(props)\n  return new($$, {\n    props = props,\n    state = {}\n  })\nend\n\nfunction $$:render(state)\n  return {}\nend\n\nreturn $$\n"

function create(what, where)
  local path = where.."/"..what..".lua"

  create_file(path)

  local file = io.open(path, 'w')

  if file then
    file:write(NEACT_COMPONENT_TEMPLATE:gsub("%$%$", what))

    file:close()
  end
end

function init()
  if #env.params > 1 then
    local action = env.params[2]

    if action == "create" and #env.params > 3 then
      local kind = env.params[3]
      local where = env.params[4]

      create(kind, where)
    end
  end

  stop_app(0)
end