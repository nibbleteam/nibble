local timeout_table = {}
local timeout_id = 0
local time = 0

function set_timeout(expires_after, fn)
  local id = timeout_id

  timeout_table[id] = {
    expires_at = time + expires_after,
    fn = fn,
    id = timeout_id
  }

  timeout_id += 1

  return id
end

function clear_timeout(id)
  timeout_table[id] = nil
end

function get_timeout(id)
  if timeout_table[id] then
    return timeout_table[id].expires_at-time
  end
end

function run_timeouts(dt)
  time += dt

  for id, timeout in pairs(timeout_table) do
    if timeout.expires_at <= time then
      timeout_table[id] = nil
      timeout.fn()
    end
  end
end
