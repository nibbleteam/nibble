local function break_name(name)
  local names = {}

  for match in name:gmatch "[^\\/]+[\\/]?" do
    push(names, match)
  end

  return names
end

-- Find an app given its name
-- Returns the app path, entrypoint and spritesheet
return function(name)
  local names = break_name(name)
  local found_nibs = {}

  for _, name in ipairs(names) do
    local search_paths = {
      -- path
      name,

      -- "name.nib"
      "apps/"..name,
      "apps/system/"..name,
      "apps/system/editors/"..name,

      -- "name"
      "apps/"..name..".nib",
      "apps/system/"..name..".nib",
      "apps/system/editors/"..name..".nib",
    }

    for _, path in ipairs(search_paths) do
      if #list_directory(path) > 0 then
        local file = io.open(path.."/main.lua", "r")
        local sheet = io.open(path.."/assets/sheet.png", "r")
        local broken_path = break_name(path)

        local name = broken_path[#broken_path]

        if file then
          push(found_nibs, {
                 name = name,

                 path = path,
                 entrypoint = path.."/main.lua",

                 spritesheet = sheet and path.."/assets/sheet.png" or nil,
          })

          file:close()
        end

        if sheet then
          sheet:close()
        end
      end
    end
  end

  return found_nibs
end
