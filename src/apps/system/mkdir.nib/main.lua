function init()
  if #env.params > 1 then
    create_directory(env.params[2])
  end

  stop_app(0)
end