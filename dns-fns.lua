local module = {}

-- TODO: Refactor to have functions as local vals rather than table members,
-- then export them at the end.
-- This is mostly important and things like scanPositions which may
-- potentially call the same function many times.
-- https://stackoverflow.com/questions/154672/what-can-i-do-to-increase-the-performance-of-a-lua-program
-- Then again, some profiling may be in order first, but I'm targeting MCU environments.
-- I've read though that table member access is slower than local access,
-- which is one reason why to use locals over globals.

function module.readUInt16BE(message, position)
  return message:byte(position) * 256 + message:byte(position + 1)
end

--- scanPositions
-- Scans over the entire message, getting positions for all the entries.
-- The Header is not included in this because its position is always 1.
-- @param message The DNS Message as a String.
-- @returns Array of numbers representing the start-positions of each thing.
--   Note that you'll need the item-counts of each section to make full sense of it.
function module.scanPositions(message)
  -- TODO: Error checking!  Size checking!  Other validations!

  local questionCount = module.readUInt16BE(message, 5)
  local answerCount = module.readUInt16BE(message, 7)
  local nameServerCount = module.readUInt16BE(message, 9)
  local additionalRecordCount = module.readUInt16BE(message, 11)
  local resourceRecordCount = answerCount + nameServerCount + additionalRecordCount

  -- Duplicate these for convenience.  We already extract them,
  -- might as well return them.
  local result = {
    questionCount = questionCount,
    answerCount = answerCount,
    nameServerCount = nameServerCount,
    additionalRecordCount = additionalRecordCount,
  }

  -- A message with no entry at all shouldn't happen, but... eh.
  -- Now < 12 would mean an error.
  if message:len() == 12 then
    return result
  end

  local currentPosition = 13
  result[#result + 1] = currentPosition

  while questionCount > 0 do
    currentPosition = module.scanQuestion(message, currentPosition)

    if currentPosition > message:len() then
      return result
    end

    result[#result + 1] = currentPosition
    questionCount = questionCount - 1
  end

  while resourceRecordCount > 0 do
    currentPosition = module.scanResourceRecord(message, currentPosition)

    if currentPosition > message:len() then
      return result
    end

    result[#result + 1] = currentPosition
    resourceRecordCount = resourceRecordCount - 1
  end

  -- TODO: Error; We shouldn't be here.
  -- It means there's extra stuff at the end of the message or we miscounted.
  return result
end

--- Returns the next position after the question at the given position.
function module.scanQuestion(message, position)
  -- A question is a name followed by 2 UInt16's.
  position = module.scanDomainName(message, position)
  return position + 4
end

--- Returns the next position after the domain name at the given position.
function module.scanDomainName(message, position)
  local length = message:byte(position)
  local lengthFlag

  while length ~= 0 do
    if length >= 0x40 then
      lengthFlag = length - (length % 0x40)

      -- 0b11 means do a jumpyjump.
      if lengthFlag == 0xe0 then
        -- The 6 LSB of the current octet + the next octet form a
        -- UInt14.  Skip past that next octet, and we're done.
        return position + 2
      end

      -- I'm not sure if 0b01 or 0b10 are actually defined, yet.
      -- A haven't felt like trawling the rest of the RFCs. (there's a lot of them)
      return position + 2
    else
      -- Skip to the next length field
      position = position + length + 1
      length = message:byte(position)
    end
  end -- while length ~= 0

  -- Skip past the 0-valued length field.
  return position + 1
end

--- Returns the next position after the resource record at the given position.
function module.scanResourceRecord(message, position)
  -- UInt16 Type + UIint16 Class + UInt32 TTL = 8 octets.
  position = module.scanDomainName(message, position) + 8
  -- Now we should be at the Record Data Length field.
  -- Add 2 to skip it, since it's a UInt16.
  return position + 2 + module.readUInt16BE(message, position)
end

return module
