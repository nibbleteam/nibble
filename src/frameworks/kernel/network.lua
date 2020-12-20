local network = {}

--local json = require "frameworks.kernel.json"
local msgpack = require "frameworks.kernel.msgpack"
local hw = require "frameworks.kernel.hw"

function network.find_players(guid, entrypoint, queue, number, name)
  name = name or "Player Nibble"

  hw.send_network_message(msgpack.pack({
                              operation = "find_players",
                              guid = guid,
                              entrypoint = entrypoint,
                              queue = queue,
                              number = number,
                              name = name,
  }))
end

function network.receive_network_message()
  local raw = hw.receive_network_message()

  if raw then
    return msgpack.unpack(raw)
  end
end

function network.send_network_message(msg)
  hw.send_network_message(msgpack.pack(msg))
end

return network
