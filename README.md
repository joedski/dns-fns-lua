dns-fns-lua
===========

Simple collection of functions for converting between raw DNS messages and tables, not tied to any underlying platform.

Naturally that means this also does nothing about actually sending and receiving these messages.

The functions are written with the intention that you only read the parts of the message you're actually interested in, and so can leave anything else untouched and create a minimum of extra values, especially tables.  It's a sizeable module, though, being a utility belt rather than a targeted library, so for space constrained end uses you should precompile it before upload.  It also trades efficiency in favor of lots of small functions.

That said, if you know you only need a subset of the functionality, just copy-paste that stuff and leave out the rest!

Given that everything and its mum usually has some DNS library built in, this is mostly useful for reading and writing various mDNS requests that they don't support, since, well, they tend not to support them.  That's what I use it for, anyway.  It can also be used to just play with DNS messages more generally, see what's actually being tossed about.



## Usage


### Available Record Data Readers

The following types of Record Data have special reader functions, to translate things into a more customary format:

- IPv4 Address, used by Record Types:
    - `A` (1)
- IPv6 Address, used by Record Types:
    - `AAAA` (28)
- Domain Name, used by Record Types:
    - `NS` (2)
    - `CNAME` (5)
    - `PTR` (12)
    - Many others, I expect...
- Collection of Strings, used by Record Types:
    - `TXT` (16)

Note that the lists of Record Types for each one are non-exhaustive.  Those are just the common ones I encountered on my home network.



## Documentation

All functions have a doc block explaining them, so there's at least that much.

TODO: Use Luadoc to make a pretty page.



## Useful Links

- [RFC 1035](https://tools.ietf.org/html/rfc1035.html), the granddaddy RFC of them all.  At least on DNS stuff, anyway.
- Wikipedia has [a sortable list of DNS Resource Record Types](https://en.wikipedia.org/wiki/List_of_DNS_record_types) because of course it does.  Useful since I didn't feel it was worth making a table mapping names to numbers in this module.
