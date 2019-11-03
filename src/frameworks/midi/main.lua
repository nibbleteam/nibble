local MIDI = {}

-- Converte uma string binária em um número,
-- considerando a string como MSB
local function decode_msb(str, bits_per_byte)
    bits_per_byte = bits_per_byte or 8

    if #str > 0 then
        local mask = math.pow(2, bits_per_byte)-1
        local mul = math.pow(2, (#str-1)*bits_per_byte)

        local value = bit.band(str:byte(), mask)

        return value*mul+decode_msb(str:sub(2), bits_per_byte)
    else
        return 0
    end
end

local function encode_msb(number, bytes)
    bytes = bytes or 1

    local str = ""

    -- Write non-zero bytes
    repeat
        str = from_ascii(number%256) .. str

        number = math.floor(number/256)
    until math.floor(number) == 0

    -- Fill up to "bytes" length
    while #str < bytes do
      str = '\00' .. str
    end

    return str
end

local function byte(data)
    local b = data.data:sub(data.ptr, data.ptr)

    data.ptr += 1

    return b:byte()
end

local function raw_byte(data)
    local b = data.data:sub(data.ptr, data.ptr)

    data.ptr += 1

    return b
end

local function varlen(data)
    local buf = ''
    local b

    repeat
        b = raw_byte(data)

        buf = buf..b
    until b:byte() <= 127

    return decode_msb(buf, 7)
end

local function read_chunk(file)
    local kind = file:read(4)

    if not kind then
        return nil
    end

    local length = decode_msb(file:read(4))
    local data = file:read(length)

    return {
        kind = kind,
        length = length,
        data = {
            data = data,
            ptr = 1,
        }
    }
end

local function read_track(data)
    local events = {}
    local status

    repeat
        local delta = varlen(data)
        local tmp_status = byte(data)

        -- Usaremos o status anterior
        if bit.band(tmp_status, 0x80) == 0 then
            data.ptr -= 1
        else
            status = tmp_status
        end

        if status == 0xff then
            local _ = byte(data)
            data.ptr += varlen(data)
        elseif status == 0xf0 then
            repeat until byte(data) == 0xf7
        elseif ({[0xd0] = true, [0xc0] = true})[bit.band(status, 0xf0)] then
        elseif ({[0x80] = true, [0x90] = true})[bit.band(status, 0xf0)] then
            local note = byte(data)
            local velocity = byte(data)

            if velocity == 0 then
                status = 0x80
            end

            insert(events, {
                       delta = delta,
                       ch = bit.band(status, 0x0f),
                       on = ({[0x90] = true})[bit.band(status, 0xf0)],
                       note = note,
                       velocity = velocity,
            })
        else
            data.ptr += 2
        end
    until data.ptr >= #data.data

    return events
end

function MIDI.read(file)
    local tracks = {}

    while true do
        local chunk = read_chunk(file)

        if not chunk then
            break
        else
            if chunk.kind == 'MTrk' then
                local events = read_track(chunk.data)

                if #events > 0 then
                    insert(tracks, events)
                end
            end
        end
    end

    return tracks
end

local function encode_varlen(number)
    local str = ""

    repeat
        local byte = bit.band(number, 127)

        if #str > 0 then
            byte += 128
        end

        str = from_ascii(byte) .. str

        number = math.floor(number/128)
    until math.floor(number) == 0

    return str
end

local function encode_event(event)
    local buffer = ""

    local status_codes = {
        [true] = 0x90, [false] = 0x80
    }

    local status_and_ch = bit.bor(status_codes[event.on], event.ch)

    buffer = buffer .. encode_varlen(event.delta)

    buffer = buffer .. from_ascii(status_and_ch)

    buffer = buffer .. from_ascii(event.note)
    buffer = buffer .. from_ascii(event.velocity)

    return buffer
end

local function encode_track(track)
    local buffer = ""

    for _, event in ipairs(track) do
        buffer = buffer .. encode_event(event)
    end

    return buffer
end

local function write_chunk(file, id, content)
    -- The ID
    file:write(id)

    -- The chunk size
    file:write(encode_msb(#content, 4))

    -- The chunk
    file:write(content)
end

local function write_track(file, track)
    write_chunk(file, 'MTrk', encode_track(track))
end

local function encode_header(tracks_count)
  local buffer = ""

  -- Format
  buffer = buffer .. encode_msb(1, 2)
  -- Ntrks
  buffer = buffer .. encode_msb(tracks_count, 2)
  -- Division
  -- Fixed at 96 ticks per 1/4 note
  buffer = buffer .. encode_msb(96, 2)

  return buffer
end

local function write_header(file, tracks)
    write_chunk(file, 'MThd', encode_header(#tracks))
end

function MIDI.write(file_name, tracks)
  -- Prepare the file for writting
  local file = io.open(file_name, "w")

  write_header(file, tracks)

  -- Write all the tracks
  for _, track in ipairs(tracks) do
      write_track(file, track)
  end

  file:close()
end

function MIDI.test_file(file_name)
    MIDI.write(file_name, {
                   {
                       { delta = 0, ch = 0, on = true, note = 48, velocity = 127 },
                       { delta = 128, ch = 0, on = false, note = 48, velocity = 0 },
                   }
    })
end

return MIDI