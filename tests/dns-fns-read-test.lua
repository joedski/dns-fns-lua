local lu = require('tests/luaunit')
local testData = require('tests/test-data')

local dnsFns = require('dns-fns')

TestDnsFnsRead = {}

function TestDnsFnsRead.test_readHeaderId()
  local cases = {
    {
      message = testData.printerPtrResponse.raw,
      messageId = testData.printerPtrResponse.table.header.id,
    },
  }

  for i, testCase in ipairs(cases) do
    lu.assertEquals(
      dnsFns.readHeaderId(testCase.message),
      testCase.messageId,
      "Case #"..i
    )
  end
end

function TestDnsFnsRead.test_readHeaderFlagsIsResponse()
  local cases = {
    {
      message = testData.printerPtrRequest.raw,
      isResponse = testData.printerPtrRequest.table.header.isResponse,
    },
    {
      message = testData.printerPtrResponse.raw,
      isResponse = testData.printerPtrResponse.table.header.isResponse,
    },
  }

  for i, testCase in ipairs(cases) do
    local headerFlags = dnsFns.readHeaderFlags(testCase.message)
    lu.assertEquals(
      dnsFns.readHeaderFlagsIsResponse(headerFlags),
      testCase.isResponse,
      "Case #"..i
    )
  end
end

function TestDnsFnsRead.test_readHeaderFlagsOpCode()
  local cases = {
    {
      message = testData.printerPtrRequest.raw,
      opCode = testData.printerPtrRequest.table.header.opCode,
    },
    {
      message = testData.printerPtrResponse.raw,
      opCode = testData.printerPtrResponse.table.header.opCode,
    },
    {
      message = testData.junkStatusResponseHeaderOnly.raw,
      opCode = testData.junkStatusResponseHeaderOnly.table.header.opCode,
    },
  }

  for i, testCase in ipairs(cases) do
    local headerFlags = dnsFns.readHeaderFlags(testCase.message)
    lu.assertEquals(
      dnsFns.readHeaderFlagsOpCode(headerFlags),
      testCase.opCode,
      "Case #"..i
    )
  end
end

function TestDnsFnsRead.test_readHeaderFlagsIsAuthoritativeAnswer()
  local cases = {
    {
      message = testData.printerPtrRequest.raw,
      isAuthoritativeAnswer = testData.printerPtrRequest.table.header.isAuthoritativeAnswer,
    },
    {
      message = testData.printerPtrResponse.raw,
      isAuthoritativeAnswer = testData.printerPtrResponse.table.header.isAuthoritativeAnswer,
    },
    {
      message = testData.junkStatusResponseHeaderOnly.raw,
      isAuthoritativeAnswer = testData.junkStatusResponseHeaderOnly.table.header.isAuthoritativeAnswer,
    },
  }

  for i, testCase in ipairs(cases) do
    local headerFlags = dnsFns.readHeaderFlags(testCase.message)
    lu.assertEquals(
      dnsFns.readHeaderFlagsIsAuthoritativeAnswer(headerFlags),
      testCase.isAuthoritativeAnswer,
      "Case #"..i
    )
  end
end

function TestDnsFnsRead.test_readHeaderFlagsIsTruncated()
  local cases = {
    {
      message = testData.printerPtrRequest.raw,
      isTruncated = testData.printerPtrRequest.table.header.isTruncated,
    },
    {
      message = testData.printerPtrResponse.raw,
      isTruncated = testData.printerPtrResponse.table.header.isTruncated,
    },
    {
      message = testData.junkStatusResponseHeaderOnly.raw,
      isTruncated = testData.junkStatusResponseHeaderOnly.table.header.isTruncated,
    },
  }

  for i, testCase in ipairs(cases) do
    local headerFlags = dnsFns.readHeaderFlags(testCase.message)
    lu.assertEquals(
      dnsFns.readHeaderFlagsIsTruncated(headerFlags),
      testCase.isTruncated,
      "Case #"..i
    )
  end
end

function TestDnsFnsRead.test_readHeaderFlagsIsRecursionDesired()
  local cases = {
    {
      message = testData.printerPtrRequest.raw,
      isRecursionDesired = testData.printerPtrRequest.table.header.isRecursionDesired,
    },
    {
      message = testData.printerPtrResponse.raw,
      isRecursionDesired = testData.printerPtrResponse.table.header.isRecursionDesired,
    },
    {
      message = testData.junkStatusResponseHeaderOnly.raw,
      isRecursionDesired = testData.junkStatusResponseHeaderOnly.table.header.isRecursionDesired,
    },
  }

  for i, testCase in ipairs(cases) do
    local headerFlags = dnsFns.readHeaderFlags(testCase.message)
    lu.assertEquals(
      dnsFns.readHeaderFlagsIsRecursionDesired(headerFlags),
      testCase.isRecursionDesired,
      "Case #"..i
    )
  end
end

function TestDnsFnsRead.test_readHeaderFlagsIsRecursionAvailable()
  local cases = {
    {
      message = testData.printerPtrRequest.raw,
      isRecursionAvailable = testData.printerPtrRequest.table.header.isRecursionAvailable,
    },
    {
      message = testData.printerPtrResponse.raw,
      isRecursionAvailable = testData.printerPtrResponse.table.header.isRecursionAvailable,
    },
    {
      message = testData.junkStatusResponseHeaderOnly.raw,
      isRecursionAvailable = testData.junkStatusResponseHeaderOnly.table.header.isRecursionAvailable,
    },
  }

  for i, testCase in ipairs(cases) do
    local headerFlags = dnsFns.readHeaderFlags(testCase.message)
    lu.assertEquals(
      dnsFns.readHeaderFlagsIsRecursionAvailable(headerFlags),
      testCase.isRecursionAvailable,
      "Case #"..i
    )
  end
end

function TestDnsFnsRead.test_readHeaderFlagsResponseCode()
  local cases = {
    {
      message = testData.printerPtrRequest.raw,
      responseCode = testData.printerPtrRequest.table.header.responseCode,
    },
    {
      message = testData.printerPtrResponse.raw,
      responseCode = testData.printerPtrResponse.table.header.responseCode,
    },
    {
      message = testData.junkStatusResponseHeaderOnly.raw,
      responseCode = testData.junkStatusResponseHeaderOnly.table.header.responseCode,
    },
  }

  for i, testCase in ipairs(cases) do
    local headerFlags = dnsFns.readHeaderFlags(testCase.message)
    lu.assertEquals(
      dnsFns.readHeaderFlagsResponseCode(headerFlags),
      testCase.responseCode,
      "Case #"..i
    )
  end
end

function TestDnsFnsRead.test_readHeaderEntryCounts()
  local cases = {
    {
      message = testData.printerPtrRequest.raw,
      counts = {
        #testData.printerPtrRequest.table.questions,
        #testData.printerPtrRequest.table.answers,
        #testData.printerPtrRequest.table.nameServers,
        #testData.printerPtrRequest.table.additionalRecords,
      },
    },
    {
      message = testData.printerPtrResponse.raw,
      counts = {
        #testData.printerPtrResponse.table.questions,
        #testData.printerPtrResponse.table.answers,
        #testData.printerPtrResponse.table.nameServers,
        #testData.printerPtrResponse.table.additionalRecords,
      },
    },
    {
      message = testData.junkStatusResponseHeaderOnly.raw,
      counts = {
        #testData.junkStatusResponseHeaderOnly.table.questions,
        #testData.junkStatusResponseHeaderOnly.table.answers,
        #testData.junkStatusResponseHeaderOnly.table.nameServers,
        #testData.junkStatusResponseHeaderOnly.table.additionalRecords,
      },
    },
  }

  for i, testCase in ipairs(cases) do
    local counts = {}
    counts[1], counts[2], counts[3], counts[4] = dnsFns.readHeaderEntryCounts(testCase.message)
    lu.assertEquals(
      counts,
      testCase.counts,
      "Case #"..i
    )
  end
end



function TestDnsFnsRead.test_readDomainName()
  -- the :sub(1, -2) is to strip off the terminal dot.
  local cases = {
    {
      message = testData.printerPtrRequest.raw,
      position = testData.printerPtrRequest.table.questions[1].offset + 1,
      domainName = testData.printerPtrRequest.table.questions[1].name:sub(1, -2),
    },
    {
      message = testData.printerPtrResponse.raw,
      position = testData.printerPtrResponse.table.answers[1].offset + 1,
      domainName = testData.printerPtrResponse.table.answers[1].name:sub(1, -2),
    },
    {
      message = testData.printerPtrResponse.raw,
      position = testData.printerPtrResponse.table.additionalRecords[1].offset + 1,
      domainName = testData.printerPtrResponse.table.additionalRecords[1].name:sub(1, -2),
    },
  }

  for i, testCase in ipairs(cases) do
    local nameParts = dnsFns.readDomainName(testCase.message, testCase.position)
    lu.assertEquals(
      table.concat(nameParts, '.'),
      testCase.domainName,
      "Case #"..i
    )
  end
end

function TestDnsFnsRead.test_readQuestionType()
  local cases = {
    {
      message = testData.printerPtrRequest.raw,
      position = testData.printerPtrRequest.table.questions[1].attributesOffset + 1,
      type = testData.printerPtrRequest.table.questions[1].type,
    },
    {
      message = testData.datamunchAddressResponse.raw,
      position = testData.datamunchAddressResponse.table.questions[1].attributesOffset + 1,
      type = testData.datamunchAddressResponse.table.questions[1].type,
    },
  }

  for i, testCase in ipairs(cases) do
    local type = dnsFns.readQuestionType(testCase.message, testCase.position)
    lu.assertEquals(
      type,
      testCase.type,
      "Case #"..i
    )
  end
end

function TestDnsFnsRead.test_readQuestionClass()
  local cases = {
    {
      message = testData.printerPtrRequest.raw,
      position = testData.printerPtrRequest.table.questions[1].attributesOffset + 1,
      class = testData.printerPtrRequest.table.questions[1].class,
    },
    {
      message = testData.datamunchAddressResponse.raw,
      position = testData.datamunchAddressResponse.table.questions[1].attributesOffset + 1,
      class = testData.datamunchAddressResponse.table.questions[1].class,
    },
  }

  for i, testCase in ipairs(cases) do
    local type = dnsFns.readQuestionClass(testCase.message, testCase.position)
    lu.assertEquals(
      type,
      testCase.class,
      "Case #"..i
    )
  end
end

function TestDnsFnsRead.test_anyReadRecordFunctions()
  error("Implement me!")
end
