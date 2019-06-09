local module = {}

-- TODO: Refactor to have functions as local vals rather than table members,
-- then export them at the end.
-- This is mostly important and things like scanPositions which may
-- potentially call the same function many times.
-- https://stackoverflow.com/questions/154672/what-can-i-do-to-increase-the-performance-of-a-lua-program
-- Then again, some profiling may be in order first, but I'm targeting MCU environments.
-- I've read though that table member access is slower than local access,
-- which is one reason why to use locals over globals.



-- ----------------
-- Utility Functions
-- ----------------



--- Utility function to check if a bit is set.
-- Used because Lua 5.1 doesn't have bitwise operators.
-- NOTE: Can only check a single bit!
-- @param val  Integer value to check bits of.
-- @param bit  Integer value representing the single bit to check.
-- @returns  Boolean indicating whether that bit is set or not.
function module.isBitSet(val, bit)
  -- functionally identical to
  --   (val & bit) != 0
  -- just less efficient.
  return (val % (bit + bit)) >= bit
end

--- Reads two octets at the given position from the message,
-- treating them as a big-endian (network-order) 16-bit unsigned int.
-- @param message  The DNS Message as a String.
-- @returns  UInt16 from the two octets at position and position + 1.
function module.readUInt16BE(message, position)
  return message:byte(position) * 256 + message:byte(position + 1)
end

function module.serializeUInt16BE(number)
  return string.char(math.floor(number / 256), number % 256)
end

-- ":0:" is never truncated.
local ipv6ZeroRuns = { '0:0:0:0:0:0:0:0', '0:0:0:0:0:0:0', '0:0:0:0:0:0', '0:0:0:0:0', '0:0:0:0', '0:0:0', '0:0' }

--- Strip the longest run of zeros in an IPv6 address
function module.stripZerosRunFromIpv6AddressString(fullString)
  local shortened

  for i = 1, #ipv6ZeroRuns do
    shortened = fullString:gsub(ipv6ZeroRuns[i], '')
    if shortened ~= fullString then
      if shortened:len() == 0 then
        return "::"
      elseif shortened:match(':$') then
        return shortened..":"
      elseif shortened:match('^:') then
        return ":"..shortened
      else
        return shortened
      end
    end
  end

  return fullString
end



-- ----------------
-- Scanning Functions
-- ----------------



--- Scans over the entire message, getting positions for all the entries.
-- and their attributes, pair wise.  That is, item 1 will be the position of the
-- first entry, item 2 will be the position of the first entry's attributes
-- which come after its name.  Item 3 will be the position of the next entry,
-- and item 4 will be the position of the next entry's attributes which come after
-- its own name.  So on, and so forth.
--
-- The Header is not included in this because its position is always 1.
-- @param message  The DNS Message as a String.
-- @returns  Mixed array whose positional elements pairs of entry and entry-attributes
--   positions in the DNS Message, and whose named elements
--   are each of the entry counts:
--   "questionCount", "answerCount", "nameServerCount", and "additionalRecordCount".
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

  local currentNamePosition = 13
  local currentAttributesPosition
  result[#result + 1] = currentNamePosition

  while questionCount > 0 do
    currentAttributesPosition, currentNamePosition = module.scanQuestion(message, currentNamePosition)
    result[#result + 1] = currentAttributesPosition

    if currentNamePosition > message:len() then
      return result
    end

    result[#result + 1] = currentNamePosition
    questionCount = questionCount - 1
  end

  while resourceRecordCount > 0 do
    currentAttributesPosition, currentNamePosition = module.scanResourceRecord(message, currentNamePosition)
    result[#result + 1] = currentAttributesPosition

    if currentNamePosition > message:len() then
      return result
    end

    result[#result + 1] = currentNamePosition
    resourceRecordCount = resourceRecordCount - 1
  end

  -- TODO: Error; We shouldn't be here.
  -- It means there's extra stuff at the end of the message or we miscounted.
  return result
end

--- Get the next position after the question at the given position.
-- @param message  The DNS Message as a String.
-- @param position  Position of the question to scan past.
-- @returns  Next position after the given question's domain name,
--   then the next position after given question's attributes.
function module.scanQuestion(message, position)
  -- A question is a name followed by 2 UInt16's.
  position = module.scanDomainName(message, position)
  return position, position + 4
end

--- Get the next position after a domain name field.
-- @param message  The DNS Message as a String.
-- @param position  Position of the domain name to scan past.
-- @returns  Next position after the given domain name.
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

--- Get the next position after a resource record.
-- @param message  The DNS Message as a String.
-- @param position  Position of the resource record to scan past.
-- @returns  Next position after the given record's domain name,
--   then the next position after given records's attributes and rdata.
function module.scanResourceRecord(message, position)
  position = module.scanDomainName(message, position)
  -- UInt16 Type + UIint16 Class + UInt32 TTL = 8 octets.
  -- Another 2 octets from the UInt16 of the Record Data Length field = 10 octets.
  -- Now we should be at the Record Data Length field.
  -- Add 2 to skip it, since it's a UInt16.
  return position, position + 10 + module.readUInt16BE(message, position + 8)
end



-- ----------------
-- Reading Functions: Header
-- ----------------



--- Reads the message ID from the header of the given message.
-- @param message  The DNS Message as a String.
-- @returns  The message ID as a UInt16.
function module.readHeaderId(message)
  return module.readUInt16BE(message, 1)
end

--- Reads all the header flags as a single UInt16 from the header.
-- Includes the op code and response code as part of it.
-- Use the various "readHeaderFlags*" functions to extract
-- parts relevant to your usage.
-- @param message  The DNS Message as a String.
-- @returns  UInt16 representing the two octets of flags and codes.
function module.readHeaderFlags(message)
  return module.readUInt16BE(message, 3)
end

--- Checks if a message's header flags indicate it is a response.
-- @param headerFlags  The header flags of a message as a UInt16.
-- @returns  Boolean representing whether or not the message is a response.
function module.readHeaderFlagsIsResponse(headerFlags)
  return module.isBitSet(headerFlags, 0x8000)
end

--- Gets the message's op code from the message header flags.
-- @param headerFlags  The header flags of a message as a UInt16.
-- @returns  The op code as an integer.
function module.readHeaderFlagsOpCode(headerFlags)
  return ((headerFlags % 0x8000) - (headerFlags % 0x0800)) / 0x0800
end

--- Checks if a message's header flags indicate it is an authoritative answer.
-- @param headerFlags  The header flags of a message as a UInt16.
-- @returns  Boolean representing whether or not the message is an authoritative answer.
function module.readHeaderFlagsIsAuthoritativeAnswer(headerFlags)
  return module.isBitSet(headerFlags, 0x0400)
end

--- Checks if a message's header flags indicate it is truncated.
-- @param headerFlags  The header flags of a message as a UInt16.
-- @returns  Boolean representing whether or not the message is truncated.
function module.readHeaderFlagsIsTruncated(headerFlags)
  return module.isBitSet(headerFlags, 0x0200)
end

--- Checks if a message's header flags indicate recursion is desired.
-- @param headerFlags  The header flags of a message as a UInt16.
-- @returns  Boolean representing whether or not recursion is desired.
function module.readHeaderFlagsIsRecursionDesired(headerFlags)
  return module.isBitSet(headerFlags, 0x0100)
end

--- Checks if a message's header flags indicate recursion is available.
-- @param headerFlags  The header flags of a message as a UInt16.
-- @returns  Boolean representing whether or not recursion is available.
function module.readHeaderFlagsIsRecursionAvailable(headerFlags)
  return module.isBitSet(headerFlags, 0x0080)
end

--- Gets the message's response code from the message header flags.
-- @param headerFlags  The header flags of a message as a UInt16.
-- @returns  The response code as an integer.
function module.readHeaderFlagsResponseCode(headerFlags)
  return headerFlags % 0x0010
end

--- Gets the entry counts of each section from the header.
-- @param message  The DNS Message as a String.
-- @returns  Four numbers representing, in order,
--   the number of questions, the number of answers,
--   the number of name-server RRs, and the number of additional records.
function module.readHeaderEntryCounts(message)
  return module.readUInt16BE(message, 5),
    module.readUInt16BE(message, 7),
    module.readUInt16BE(message, 9),
    module.readUInt16BE(message, 11)
end



-- ----------------
-- Reading Functions: Entries
-- ----------------



--- Reads a domain name at a given position.
-- Note that both Questions and Resource Records start with the Domain Name,
-- so the position of a Question or Resource Record can be treated as the same as the
-- position of a Domain Name.  Domain Names can appear in RData fields, too, of course.
-- @param message  The DNS Message as a String.
-- @param position  Position of the first length-field of a Domain Name.
-- @returns  Array of Name Parts in the Domain Name, _not_ including the last
--   zero-length Name Part.
function module.readDomainName(message, position)
  local nameParts = {}
  local length = message:byte(position)
  local lengthFlag

  while length ~= 0 do
    if length >= 0x40 then
      lengthFlag = length - (length % 0x40)

      if lengthFlag == 0xc0 then
        -- 0b11 means do a jumpyjump.
        -- +1 because lua is 1-indexed.
        position = (module.readUInt16BE(message, position) % 0x4000) + 1
        length = message:byte(position)
      else
        -- I'm not sure if 0b01 or 0b10 are actually defined, yet.
        -- A haven't felt like trawling the rest of the RFCs. (there's a lot of them)
        position = position + 1
        break
      end
    else
      -- Read the octet sequence, then skip to the next length field
      table.insert(nameParts, message:sub(position + 1, position + length))
      position = position + length + 1
      length = message:byte(position)
    end
  end -- while length ~= 0

  return nameParts, position + 1
end

--- Reads the Type field of a Question at the given Question's attributes' position.
-- @param message  The DNS Message as a String.
-- @param attributesPosition  The position after the Question's Name field, where the first attribute starts.
-- @returns  The Question Type as a UInt16.
function module.readQuestionType(message, attributesPosition)
  return module.readUInt16BE(message, attributesPosition)
end

--- Reads the Class field of a Question at the given Question's attributes' position.
-- This is almost always going to be `1` for Internet, but eh,
-- you can read it anyway?
-- @param message  The DNS Message as a String.
-- @param attributesPosition  The position after the Question's Name field, where the first attribute starts.
-- @returns  The Question Type as a UInt16.
function module.readQuestionClass(message, attributesPosition)
  return module.readUInt16BE(message, attributesPosition + 2)
end

--- Reads the Type field of a Resource Record at
-- the given Resource Record's attributes' position.
-- @param message  The DNS Message as a String.
-- @param attributesPosition  The position after the Resource Record's Name field, where the first attribute starts.
-- @returns  The Resource Record Type as a UInt16.
function module.readRecordType(message, attributesPosition)
  return module.readUInt16BE(message, attributesPosition)
end

--- Reads the Class field of a Resource Record at
-- the given Resource Record's attributes' position.
-- This is almost always going to be `1` for Internet, but eh,
-- you can read it anyway?
-- @param message  The DNS Message as a String.
-- @param attributesPosition  The position after the Resource Record's Name field, where the first attribute starts.
-- @returns  The Resource Record Type as a UInt16.
function module.readRecordClass(message, attributesPosition)
  return module.readUInt16BE(message, attributesPosition + 2)
end

--- Reads the TTL field of a Resource Record at
-- the given Resource Record's attributes' position.
-- @param message  The DNS Message as a String.
-- @param attributesPosition  The position after the Resource Record's Name field, where the first attribute starts.
-- @returns  The Resource Record TTL in seconds as a UInt32.
function module.readRecordTtl(message, attributesPosition)
  return module.readUInt16BE(message, attributesPosition + 4) * 65536 +
    module.readUInt16BE(message, attributesPosition + 6)
end

--- Reads the Data Length field of a Resource Record at
-- the given Resource Record's attributes' position.
-- @param message  The DNS Message as a String.
-- @param attributesPosition  The position after the Resource Record's Name field, where the first attribute starts.
-- @returns  The number of octets the Record Data takes up as a UInt16.
function module.readRecordDataLength(message, attributesPosition)
  return module.readUInt16BE(message, attributesPosition + 8)
end

--- Reads the Record Data as a raw string of octets.
-- Probably not useful, but sometimes you just want the data itself.
-- Usually, though, a more specific Record Data Reader should be used.
-- @param message  The DNS Message as a String.
-- @param attributesPosition  The position after the Resource Record's Name field, where the first attribute starts.
-- @returns  The Record Data as a raw string of octets.
function module.readRecordDataAsRawString(message, attributesPosition)
  local dataLength = module.readRecordDataLength(message, attributesPosition)
  local dataPosition = attributesPosition + 10
  return message:sub(dataPosition, dataPosition + dataLength - 1)
end

--- Reads the Record Data as an IPv4 Address String,
-- formatting it into the customary textual expression.
--
-- Use this with the Record Type A (1).
-- @param message  The DNS Message as a String.
-- @param attributesPosition  The position after the Resource Record's Name field, where the first attribute starts.
-- @returns  The Record Data formatted as an IPv4 Address String.
function module.readRecordDataAsIpv4AddressString(message, attributesPosition)
  local dataLength = module.readRecordDataLength(message, attributesPosition)
  -- TODO: Validate data length?  (Should be 4)
  local dataPosition = attributesPosition + 10
  return string.format(
    '%d.%d.%d.%d',
    message:byte(dataPosition),
    message:byte(dataPosition + 1),
    message:byte(dataPosition + 2),
    message:byte(dataPosition + 3)
  )
end

--- Reads the Record Data as an IPv6 Address String,
-- formatting it into the customary textual expression,
-- with leading 0's truncated, as well as the largest contiguous
-- run of 0-hextets truncated to "::".
--
-- Use this with the Record Type AAAA (28).
-- @param message  The DNS Message as a String.
-- @param attributesPosition  The position after the Resource Record's Name field, where the first attribute starts.
-- @returns  The Record Data formatted as an IPv6 Address String.
function module.readRecordDataAsIpv6AddressString(message, attributesPosition)
  local dataLength = module.readRecordDataLength(message, attributesPosition)
  -- TODO: Validate data length?  (should be 16)
  local dataPosition = attributesPosition + 10
  local fullString = table.concat({
    string.format('%x', module.readUInt16BE(message, dataPosition)),
    string.format('%x', module.readUInt16BE(message, dataPosition + 2)),
    string.format('%x', module.readUInt16BE(message, dataPosition + 4)),
    string.format('%x', module.readUInt16BE(message, dataPosition + 6)),
    string.format('%x', module.readUInt16BE(message, dataPosition + 8)),
    string.format('%x', module.readUInt16BE(message, dataPosition + 10)),
    string.format('%x', module.readUInt16BE(message, dataPosition + 12)),
    string.format('%x', module.readUInt16BE(message, dataPosition + 14)),
  }, ':')

  return module.stripZerosRunFromIpv6AddressString(fullString)
end

--- Reads the Record Data as a Domain Name.
--
-- Use this with the Record Types NS (2), PTR (12), CNAME (5), ... others.
-- @param message  The DNS Message as a String.
-- @param attributesPosition  The position after the Resource Record's Name field, where the first attribute starts.
-- @returns  Array of Domain Name parts.
function module.readRecordDataAsDomainName(message, attributesPosition)
  local dataLength = module.readRecordDataLength(message, attributesPosition)
  -- TODO: Validate dataLength doesn't exceed the allow domain name length?
  -- Or is that too complicated with pointers?
  local dataPosition = attributesPosition + 10

  return module.readDomainName(message, dataPosition)
end

--- Reads the Record Data as a series of Character Strings.
--
-- Use this with the Record Type TXT (16)
-- @param message  The DNS Message as a String.
-- @param attributesPosition  The position after the Resource Record's Name field, where the first attribute starts.
-- @returns  Array of Character Strings, which is really just an array of strings.
--   Do with them what you will.
function module.readRecordDataAsCharacterStrings(message, attributesPosition)
  local dataLength = module.readRecordDataLength(message, attributesPosition)
  local dataPosition = attributesPosition + 10

  local characterStrings = {}
  local stringLength = message:byte(dataPosition)

  while stringLength ~= 0 do
    -- TODO: Validate we have enough message left to read.
    table.insert(
      characterStrings,
      message:sub(dataPosition + 1, dataPosition + stringLength)
    )

    dataPosition = dataPosition + stringLength + 1
    stringLength = message:byte(dataPosition)
  end

  return characterStrings
end



-- ----------------
-- Writing Functions
-- ----------------

--- Creates a new DNS Message Intermediate.
-- Add questions and other records to it with `writeQuestion()`
-- and `writeResourceRecord()`, then convert it to octets with
-- `serializeMessage()`.
function module.initMessage(id, flags)
  return {
    module.serializeUInt16BE(id),
    module.serializeUInt16BE(flags),
    0,
    0,
    0,
    0,
  }
end

--- Writes a single question to the given DNS Message Intermediate.
function module.writeQuestion(message, name, type, class)
  local questionOctets = {
    module.serializeDomainName(name),
    module.serializeUInt16BE(type),
    module.serializeUInt16BE(class),
  }

  table.insert(message, table.concat(questionOctets))
  message[3] = message[3] + 1

  return message
end

--- Writes a single resource record of some given kind to the
-- given DNS Message Intermediate.
function module.writeResourceRecord(message, recordKind, name, type, class, ttl, recordData)
  if recordKind ~= 'answer' and recordKind ~= 'nameServer' and recordKind ~= 'additionalRecord' then
    error('"'..recordKind..'" is not a supported kind of record; use one of "answer", "nameServer", or "additionalRecord"')
  end

  local recordKindIndex
  local resourceRecordOctets = {
    module.serializeDomainName(name),
    module.serializeUInt16BE(type),
    module.serializeUInt16BE(class),
    module.serializeUInt16BE(math.floor(ttl / 65536)),
    module.serializeUInt16BE(ttl % 65536),
    recordData,
  }

  table.insert(message, table.concat(resourceRecordOctets))

  if recordKind == 'answer' then recordKindIndex = 4
  elseif recordKind == 'nameServer' then recordKindIndex = 5
  else recordKindIndex = 6
  end
  message[recordKindIndex] = message[recordKindIndex] + 1

  return message
end

--- Serializes a domain name.  Does not perform any sort of compression.
function module.serializeDomainName(name)
  if type(name) == 'table' then
    local nameParts = {}
    for i in 1, #name do
      table.insert(nameParts, string.char(#(name[i])))
      table.insert(nameParts, name[i])
    end
    return table.concat(nameParts)
  elseif type(name) == 'string' then
    local nameParts = {}
    local lastStart = 1
    local nextStart = name.find('.', lastStart, true)
    while nextStart ~= nil do
      table.insert(nameParts, string.char(matchStart - 1))
      table.insert(nameParts, name.sub(lastStart, nextStart - 1))
      -- +1 to skip the dot.
      lastStart = nextStart + 1
      nextStart = name.find('.', lastStart, true)
    end
    local lastPart = name.sub(lastStart, -1)
    table.insert(nameParts, string.char(#lastPart))
    table.insert(nameParts, lastPart)
    return table.concat(nameParts)
  end

  error('"'..type(name)..'" is not a supported type for names; use a table of strings or a "."-delimited string')
end

--- Serializes a DNS Message Intemediate into octets.
-- This mutates the message intemediate, so don't reuse it afterwards.
function module.serializeMessage(message)
  message[3] = module.serializeUInt16BE(message[3])
  message[4] = module.serializeUInt16BE(message[4])
  message[5] = module.serializeUInt16BE(message[5])
  message[6] = module.serializeUInt16BE(message[6])
  return table.concat(message)
end



return module
