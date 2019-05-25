-- Run this from the project root:
--   lua test/test.lua

local lu = require('tests/luaunit')

require('tests/dns-fns-scan-test')

lu.LuaUnit.verbosity = 2
os.exit(lu.LuaUnit.run())