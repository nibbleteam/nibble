local network = {}

local json = require "frameworks.kernel.json"
--local msgpack = require "frameworks.kernel.msgpack"
local hw = require "frameworks.kernel.hw"

local KEEP_MESSAGES = 32

-- Current sequence number
local seq = 0
-- Last message stored in memory that we can resend
local last_kept = 0
-- Expected sequence number for all known hosts
local expected_seq = {}
-- Messages that can be resent
local messages = {}

function network.find_players(guid, entrypoint, queue, number, name)
  name = name or "Player Nibble"

  hw.send_network_message(json.encode({
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
    local msg = json.decode(raw)

    if msg.msg.resend then
      return network.resend_message(msg.msg.resend)
    else
      if msg.seq then
        if expected_seq[msg.from.guid] then
          if msg.seq > expected_seq[msg.from.guid] then
            hw.send_network_message(json.encode({
                                        routing = {
                                          guid = msg.from.guid,
                                        },
                                        msg = { resend = expected_seq[msg.from.guid] },
                                        operation = "private_message",
                                        guid = network_guid,
                                        entrypoint = ""
            }))
          elseif msg.seq < expected_seq[msg.from.guid] then
            -- TODO: log this network error!
            expected_seq[msg.from.guid] = msg.seq+1
          else
            expected_seq[msg.from.guid] = msg.seq+1
          end
        else
          expected_seq[msg.from.guid] = msg.seq+1
        end
      end

      return msg
    end
  end
end

function network.resend_message(n)
  if messages[n] then
    hw.send_network_message(json.encode(messages[n]))
  end
end

function network.send_network_message(msg)
  -- Store to allow for resends
  msg.seq = seq
  messages[seq] = msg

  -- Send
  hw.send_network_message(json.encode(msg))
  network.cleanup_stored_messages()

  -- Prepare to send next
  seq += 1
end

function network.cleanup_stored_messages()
  while seq-last_kept >= KEEP_MESSAGES do
    messages[last_kept] = nil
    last_kept += 1
  end
end

return network
