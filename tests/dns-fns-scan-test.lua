local lu = require('tests/luaunit')
local testData = require('tests/test-data')

local dnsFns = require('dns-fns')

TestDnsFnsScan = {}

function TestDnsFnsScan.test_scanDomainName()
  local cases = {
    {
      message = testData.printerPtrRequest.raw,
      entryPosition = testData.printerPtrRequest.table.questions[1].offset + 1,
      entryAttributesPosition = testData.printerPtrRequest.table.questions[1].attributesOffset + 1,
    },
    -- These two are fun because each one's name is literally just a pointer.
    {
      message = testData.printerPtrResponse.raw,
      entryPosition = testData.printerPtrResponse.table.answers[1].offset + 1,
      entryAttributesPosition = testData.printerPtrResponse.table.answers[1].attributesOffset + 1,
    },
    {
      message = testData.printerPtrResponse.raw,
      entryPosition = testData.printerPtrResponse.table.additionalRecords[2].offset + 1,
      entryAttributesPosition = testData.printerPtrResponse.table.additionalRecords[2].attributesOffset + 1,
    },
  }

  for i, testCase in ipairs(cases) do
    lu.assertEquals(
      dnsFns.scanDomainName(testCase.message, testCase.entryPosition),
      testCase.entryAttributesPosition,
      "Case #"..i
    )
  end
end

function TestDnsFnsScan.test_scanQuestion()
  local cases = {
    {
      message = testData.printerPtrResponse.raw,
      entryPosition = testData.printerPtrResponse.table.questions[1].offset + 1,
      resultPositions = {
        testData.printerPtrResponse.table.questions[1].attributesOffset + 1,
        testData.printerPtrResponse.table.answers[1].offset + 1,
      },
    }
  }

  for i, testCase in ipairs(cases) do
    local result = {}
    result[1], result[2] = dnsFns.scanQuestion(testCase.message, testCase.entryPosition)
    lu.assertEquals(
      result,
      testCase.resultPositions,
      "Case #"..i
    )
  end
end

function TestDnsFnsScan.test_scanResourceRecord()
  local cases = {
    {
      message = testData.printerPtrResponse.raw,
      recordPosition = testData.printerPtrResponse.table.answers[1].offset + 1,
      resultPositions = {
        testData.printerPtrResponse.table.answers[1].attributesOffset + 1,
        testData.printerPtrResponse.table.nameServersOffset + 1,
      }
    },
    {
      message = testData.printerPtrResponse.raw,
      recordPosition = testData.printerPtrResponse.table.additionalRecords[1].offset + 1,
      resultPositions = {
        testData.printerPtrResponse.table.additionalRecords[1].attributesOffset + 1,
        testData.printerPtrResponse.table.additionalRecords[2].offset + 1,
      }
    },
  }

  for i, testCase in ipairs(cases) do
    local result = {}
    result[1], result[2] = dnsFns.scanResourceRecord(testCase.message, testCase.recordPosition)
    lu.assertEquals(
      result,
      testCase.resultPositions,
      "Case #"..i
    )
  end
end

function TestDnsFnsScan.test_scanPositions()
  local cases = {
    {
      message = testData.printerPtrRequest.raw,
      result = {
        testData.printerPtrResponse.table.questions[1].offset + 1,
        testData.printerPtrResponse.table.questions[1].attributesOffset + 1,
        questionCount = 1,
        answerCount = 0,
        nameServerCount = 0,
        additionalRecordCount = 0,
      },
    },
    {
      message = testData.printerPtrResponse.raw,
      result = {
        testData.printerPtrResponse.table.questions[1].offset + 1,
        testData.printerPtrResponse.table.questions[1].attributesOffset + 1,
        testData.printerPtrResponse.table.answers[1].offset + 1,
        testData.printerPtrResponse.table.answers[1].attributesOffset + 1,
        -- no nameServers
        testData.printerPtrResponse.table.additionalRecords[1].offset + 1,
        testData.printerPtrResponse.table.additionalRecords[1].attributesOffset + 1,
        testData.printerPtrResponse.table.additionalRecords[2].offset + 1,
        testData.printerPtrResponse.table.additionalRecords[2].attributesOffset + 1,
        testData.printerPtrResponse.table.additionalRecords[3].offset + 1,
        testData.printerPtrResponse.table.additionalRecords[3].attributesOffset + 1,
        questionCount = 1,
        answerCount = 1,
        nameServerCount = 0,
        additionalRecordCount = 3,
      },
    }
  }

  for i, testCase in ipairs(cases) do
    lu.assertEquals(
      dnsFns.scanPositions(testCase.message),
      testCase.result,
      "Case #"..i
    )
  end
end
