local lu = require('tests/luaunit')
local testData = require('tests/test-data')

local dnsFns = require('dns-fns')

TestDnsFnsScan = {}

function TestDnsFnsScan.test_scanDomainName()
  local cases = {
    {
      message = testData.printerPtrRequest.raw,
      questionPosition = testData.printerPtrRequest.table.questions[1].offset + 1,
      questionAttributesPosition = testData.printerPtrRequest.table.questions[1].attributesOffset + 1,
    },
    -- These two are fun because each one's name is literally just a pointer.
    {
      message = testData.printerPtrResponse.raw,
      questionPosition = testData.printerPtrResponse.table.answers[1].offset + 1,
      questionAttributesPosition = testData.printerPtrResponse.table.answers[1].attributesOffset + 1,
    },
    {
      message = testData.printerPtrResponse.raw,
      questionPosition = testData.printerPtrResponse.table.additionalRecords[2].offset + 1,
      questionAttributesPosition = testData.printerPtrResponse.table.additionalRecords[2].attributesOffset + 1,
    },
  }

  for i, testCase in ipairs(cases) do
    lu.assertEquals(
      dnsFns.scanDomainName(testCase.message, testCase.questionPosition),
      testCase.questionAttributesPosition,
      "Expected case #"..i.." to match attributes position "..testCase.questionAttributesPosition
    )
  end
end

function TestDnsFnsScan.test_scanQuestion()
  local cases = {
    {
      message = testData.printerPtrResponse.raw,
      questionPosition = testData.printerPtrResponse.table.questions[1].offset + 1,
      nextItemPosition = testData.printerPtrResponse.table.answers[1].offset + 1,
    }
  }

  for i, testCase in ipairs(cases) do
    lu.assertEquals(
      dnsFns.scanQuestion(testCase.message, testCase.questionPosition),
      testCase.nextItemPosition,
      "Expected case #"..i.." to match next item position "..testCase.nextItemPosition
    )
  end
end

function TestDnsFnsScan.test_scanResourceRecord()
  local cases = {
    {
      message = testData.printerPtrResponse.raw,
      recordPosition = testData.printerPtrResponse.table.answersOffset + 1,
      nextRecordPosition = testData.printerPtrResponse.table.nameServersOffset + 1,
    },
    {
      message = testData.printerPtrResponse.raw,
      recordPosition = testData.printerPtrResponse.table.additionalRecordsOffset + 1,
      nextRecordPosition = testData.printerPtrResponse.table.additionalRecords[2].offset + 1,
    },
  }

  for i, testCase in ipairs(cases) do
    lu.assertEquals(
      dnsFns.scanResourceRecord(testCase.message, testCase.recordPosition),
      testCase.nextRecordPosition,
      "Expected case #"..i.." to match next record position "..testCase.nextRecordPosition
    )
  end
end

function TestDnsFnsScan.test_scanPositions()
  local cases = {
    {
      message = testData.printerPtrRequest.raw,
      result = {
        testData.printerPtrResponse.table.questions[1].offset + 1,
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
        testData.printerPtrResponse.table.answers[1].offset + 1,
        -- no nameServers
        testData.printerPtrResponse.table.additionalRecords[1].offset + 1,
        testData.printerPtrResponse.table.additionalRecords[2].offset + 1,
        testData.printerPtrResponse.table.additionalRecords[3].offset + 1,
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
      "Expected case #"..i.." to match"
    )
  end
end
