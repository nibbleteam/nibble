function init()
  if #env.params > 1 then
    os.remove(env.params[2])
  end

  stop_app(0)
end