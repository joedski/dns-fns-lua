local lu = require('tests/luaunit')

local dnsFns = require('dns-fns')



TestDnsFnsUtil = {}

function TestDnsFnsUtil.test_stripZerosRunFromIpv6AddressString()
  local cases = {
    {
      fullString = '0:0:0:0:0:0:0:0',
      shortened = '::',
    },
    {
      fullString = 'beef:0:0:0:0:0:0:0',
      shortened = 'beef::',
    },
    {
      fullString = '0:0:0:0:0:0:0:beef',
      shortened = '::beef',
    },
    {
      fullString = 'dead:0:0:0:0:0:0:beef',
      shortened = 'dead::beef',
    },
    {
      fullString = 'dead:beef:0:0:0:0:0:0',
      shortened = 'dead:beef::',
    },
    {
      fullString = '0:0:0:0:0:0:dead:beef',
      shortened = '::dead:beef',
    },
    {
      fullString = 'dead:0:0:0:ca7:0:0:beef',
      shortened = 'dead::ca7:0:0:beef',
    },
    {
      fullString = 'feed:dead:beef:0:ca7:f00d:0:ba95',
      shortened = 'feed:dead:beef:0:ca7:f00d:0:ba95',
    },
    {
      fullString = '0:feed:dead:beef:ca7:f00d:0:ba95',
      shortened = '0:feed:dead:beef:ca7:f00d:0:ba95',
    },
    {
      fullString = '0:feed:dead:beef:ca7:f00d:ba95:0',
      shortened = '0:feed:dead:beef:ca7:f00d:ba95:0',
    },
  }

  for i, testCase in ipairs(cases) do
    lu.assertEquals(
      dnsFns.stripZerosRunFromIpv6AddressString(testCase.fullString),
      testCase.shortened,
      "Case #"..i
    )
  end
end
