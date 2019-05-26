local module = {}

-- NOTE: Any table value labeled "offset" is a zero-indexed value.
-- To get the first char there, take offset + 1.
-- To get the last char, take nextOffset as is, since string.sub is end-inclusive.

-- I made a printer request on my local network.
module.printerPtrRequest = {
  raw = '\120\172\000\000\000\001\000\000\000\000\000\000\008\095\112\114\105\110\116\101\114\004\095\116\099\112\005\108\111\099\097\108\000\000\012\000\001',
  table = {
    header = {
      id = 30892,
      isResponse = false,
      opCode = 0,
      isAuthoritativeAnswer = false,
      isTruncated = false,
      isRecursionDesired = false,
      isRecursionAvailable = false,
      responseCode = 0,
    },
    questionsOffset = 12,
    questions = {
      {
        name = "_printer._tcp.local.",
        type = 12,
        class = 1,
        offset = 12,
        attributesOffset = 12 + 21,
      }
    },
    answers = {},
    nameServers = {},
    additionalRecords = {}
  },
}

-- This is what the printer sent back.
-- It's nice because it includes resource records of types PTR, SRV, TXT, and A, all in one response.
module.printerPtrResponse = {
  raw = '\120\172\132\000\000\001\000\001\000\000\000\003\008\095\112\114\105\110\116\101\114\004\095\116\099\112\005\108\111\099\097\108\000\000\012\000\001\192\012\000\012\000\001\000\000\000\010\000\023\020\069\080\083\079\078\032\087\080\045\052\053\051\048\032\083\101\114\105\101\115\192\012\192\049\000\033\000\001\000\000\000\010\000\020\000\000\000\000\002\003\011\069\080\083\079\078\055\051\066\053\069\065\192\026\192\049\000\016\000\001\000\000\000\010\000\205\009\116\120\116\118\101\114\115\061\049\011\112\114\105\111\114\105\116\121\061\053\048\023\116\121\061\069\080\083\079\078\032\087\080\045\052\053\051\048\032\083\101\114\105\101\115\013\117\115\098\095\077\070\071\061\069\080\083\079\078\022\117\115\098\095\077\068\076\061\087\080\045\052\053\051\048\032\083\101\114\105\101\115\030\112\114\111\100\117\099\116\061\040\069\080\083\079\078\032\087\080\045\052\053\051\048\032\083\101\114\105\101\115\041\007\112\100\108\061\114\097\119\007\114\112\061\097\117\116\111\008\113\116\111\116\097\108\061\049\058\097\100\109\105\110\117\114\108\061\104\116\116\112\058\047\047\069\080\083\079\078\055\051\066\053\069\065\046\108\111\099\097\108\046\058\056\048\047\080\082\069\083\069\078\084\065\084\073\079\078\047\066\079\078\074\079\085\082\005\110\111\116\101\061\000\192\090\000\001\000\001\000\000\000\010\000\004\192\168\200\101',
  table = {
    header = {
      id = 30892,
      isResponse = true,
      opCode = 0,
      isAuthoritativeAnswer = true,
      isTruncated = false,
      isRecursionDesired = false,
      isRecursionAvailable = false,
      responseCode = 0,
    },
    -- header size is always 12 octets.
    questionsOffset = 12,
    questions = {
      {
        name = "_printer._tcp.local.",
        type = 12,
        class = 1,
        offset = 12,
        attributesOffset = 12 + 21,
      }
    },
    -- It's not required that any particular section or record/entry be an even number of octets.
    answersOffset = 37,
    answers = {
      {
        name = "_printer._tcp.local.",
        type = 12, -- PTR
        class = 1,
        ttl = 10,
        -- This includes a domain-name-pointer at the end, the \192\012.
        dataRaw = '\020\069\080\083\079\078\032\087\080\045\052\053\051\048\032\083\101\114\105\101\115\192\012',
        -- domainName = "EPSON WP-4530 Series._printer._tcp.local."
        offset = 37,
        attributesOffset = 39,
        recordDataOffset = 49,
      }
    },
    nameServersOffset = 72,
    nameServers = {},
    -- empty sections are zero-length!
    additionalRecordsOffset = 72,
    additionalRecords = {
      {
        name = "EPSON WP-4530 Series._printer._tcp.local.",
        type = 33, -- SRV
        class = 1,
        ttl = 10,
        dataRaw = '\000\000\000\000\002\003\011\069\080\083\079\078\055\051\066\053\069\065\192\026',
        -- 0000.0000.0203.0b=4550534f4e373342354541.c01a
        -- uint16 Priority, uint16 Weight, uint16 Port, domain-name Target
        offset = 72,
        -- This name is also only a pointer because it points at the RDATA of answers[1].
        attributesOffset = 74,
        recordDataOffset = 84,
      },
      {
        name = "EPSON WP-4530 Series._printer._tcp.local.",
        type = 16, -- TXT
        class = 1,
        ttl = 10,
        texts = {
          "txtvers=1",
          "priority=50",
          "ty=EPSON WP-4530 Series",
          "usb_MFG=EPSON",
          "usb_MDL=WP-4530 Series",
          "product=(EPSON WP-4530 Series)",
          "pdl=raw",
          "rp=auto",
          "qtotal=1",
          "adminurl=http://EPSON73B5EA.local.:80/PRESENTATION/BONJOUR",
          "note="
        },
        dataRaw = "\009\116\120\116\118\101\114\115\061\049\011\112\114\105\111\114\105\116\121\061\053\048\023\116\121\061\069\080\083\079\078\032\087\080\045\052\053\051\048\032\083\101\114\105\101\115\013\117\115\098\095\077\070\071\061\069\080\083\079\078\022\117\115\098\095\077\068\076\061\087\080\045\052\053\051\048\032\083\101\114\105\101\115\030\112\114\111\100\117\099\116\061\040\069\080\083\079\078\032\087\080\045\052\053\051\048\032\083\101\114\105\101\115\041\007\112\100\108\061\114\097\119\007\114\112\061\097\117\116\111\008\113\116\111\116\097\108\061\049\058\097\100\109\105\110\117\114\108\061\104\116\116\112\058\047\047\069\080\083\079\078\055\051\066\053\069\065\046\108\111\099\097\108\046\058\056\048\047\080\082\069\083\069\078\084\065\084\073\079\078\047\066\079\078\074\079\085\082\005\110\111\116\101\061\000",
        offset = 104,
        attributesOffset = 106,
        recordDataOffset = 116,
      },
      {
        name = "EPSON73B5EA.local.",
        type = 1, -- A
        class = 1,
        ttl = 10,
        dataRaw = "\192\168\200\101",
        address = "192.168.200.101",
        offset = 321,
        -- This record's name is also only a pointer because it points at somewhere in additionalRecords[2]'s RDATA.
        attributesOffset = 323,
        recordDataOffset = 333,
      },
    },
  },
}

-- I'm not sure a response would ever look like this,
-- but it's technically the right shape, if you disregard
-- that all the records are empty.
-- This should only be used for header tests.
module.junkStatusResponseHeaderOnly = {
  raw = "\190\239\151\129\000\002\000\002\000\001\000\003",
  table = {
    header = {
      id = 0xbeef,
      isResponse = true,
      opCode = 0x02, -- STATUS
      isAuthoritativeAnswer = true,
      isTruncated = true,
      isRecursionDesired = true,
      isRecursionAvailable = true,
      responseCode = 1, -- FORMAT_ERROR
    },
    questions = {{}, {}},
    answers = {{}, {}},
    nameServers = {{}},
    additionalRecords = {{}, {}, {}},
  }
}

module.datamunchAddressRequest = {
  raw = "\190\239\132\000\000\001\000\001\000\000\000\000\009\100\097\116\097\109\117\110\099\104\005\108\111\099\097\108\000\000\001\000\001\192\012\000\001\000\001\000\000\000\010\000\004\192\168\200\073",
  table = {
    header = {
      id = 48879,
      isResponse = true,
      opCode = 0,
      isAuthoritativeAnswer = true,
      isTruncated = false,
      isRecursionDesired = false,
      isRecursionAvailable = false,
      responseCode = 0
    },
    questions = {
      {
        name = "datamunch.local.",
        type = 1,
        class = 1,
        offset = 12,
        attributesOffset = 29,
      }
    },
    answers = {
      {
        name = "datamunch.local.",
        type = 1,
        class = 1,
        ttl = 10,
        dataRaw = "\192\168\200\073",
        -- address = "192.168.200.73",
        offset = 33,
        attributesOffset = 35,
        recordDataOffset = 45,
      }
    },
    nameServers = {},
    additionalRecords = {},
    -- Offsets!
    questionsOffset = 12,
    answersOffset = 33,
    nameServersOffset = 49,
    additionalRecordsOffset = 49
  }
}

return module
