-- # Lualit Loader
--
-- Tools for loading and parsing `.lualit` files.

local loader = {}
local lit = require("lualit.lit_parser")

-- Create a searchpath for lualit files.
-- Used by register_loader to create `package.lualit_path` property.
local function create_lualit_path(lua_path)
  local lualit_paths = {}
  -- Loop through `;`-delimited string
  for template in string.gmatch(lua_path, "([^;]+)") do
    -- Find any .lua path templates and create a `.lualit` template for each
    -- of them.
    local initial = template:match("^(.-)%.lua$")
    if initial then
      table.insert(lualit_paths, initial .. ".lualit")
      table.insert(lualit_paths, initial .. ".lua.md")
    end
  end
  -- Join path table with delimiter and return string.
  return table.concat(lualit_paths, ";")
end

function loader.load(s)
  return load(lit.parse_to_lua(s))
end

function loader.read_all(file_path)
  local file = io.open(file_path, "rb")
  if file then
    -- Compile and return the module
    local s = file:read("*a")
    file:close()
    if s then
      return s
    end
    return nil, string.format('Could not read file "%s"', file_path)
  end
  return nil, string.format('Could not find file "%s"', file_path)
end

function loader.loadfile(file_path)
  local s, err = loader.read_all(file_path)
  if not s then
    return s, err
  else
    return loader.load(s)
  end
end

-- See "Compilation, Execution, and Errors", https://www.lua.org/pil/8.html
function loader.dofile(file_path)
  local f = assert(loader.loadfile(file_path))
  return f()
end

-- Lualit module loader. You can register this to be able to load `.lualit`
-- files directly with `require`.
function loader.load_module(name)
  -- http://lua-users.org/wiki/LuaModulesLoader
  local errmsg = ""
  -- Find source
  local module_path = string.gsub(name, "%.", "/")
  for path in string.gmatch(package.lualit_path, "([^;]+)") do
    local file_path = string.gsub(path, "%?", module_path)
    local lua = loader.loadfile(file_path)
    if lua then
      return lua
    end
    errmsg = errmsg .. string.format("\n\tno file '%s'", file_path)
  end
  return errmsg
end

-- Registers the module loader.
-- Call this at the entry point of your scripts.
function loader.register_loader()
  package.lualit_path = create_lualit_path(package.path)

  -- Insert just after the standard .lua package loader
  -- This ensures that "compiled" .lua files are favored over .lualit.
  table.insert(package.searchers, 2, loader.load_module)
  return true
end

return loader
