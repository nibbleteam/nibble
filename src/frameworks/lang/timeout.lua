local timeout_table = {}
local timeout_id = 0
local time = 0

function set_timeout(expires_after, fn)
  insert(timeout_table, {
           expires_at = time + expires_after,
           fn = fn,
           id = timeout_id
  })

  timeout_id += 1
end

function clear_timeout(id)
  for i=#timeout_table,1,-1 do
    if timeout_table[i].id == id then
        remove(timeout_table, i)
        break
    end
  end
end

function run_timeouts(dt)
  time += dt

  for i=#timeout_table,1,-1 do
    if timeout_table[i].expires_at <= time then
      local timeout = timeout_table[i]

      remove(timeout_table, i)

      timeout.fn()
    end
  end
end
