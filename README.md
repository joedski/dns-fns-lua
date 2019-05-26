dns-fns-lua
===========

Simple collection of functions for converting between raw DNS messages and tables, not tied to any underlying platform.

Naturally that means this also does nothing about actually sending and receiving these messages.

The functions are written with the intention that you only read the parts of the message you're actually interested in, and so can leave anything else untouched and create a minimum of extra values, especially tables.  It's a sizeable module, though, being a utility belt rather than a targeted library, so for space constrained end uses you should precompile it before upload.  It also trades efficiency in favor of lots of small functions.

That said, if you know you only need a subset of the functionality, just copy-paste that stuff and leave out the rest!

Given that everything and its mum usually has some DNS library built in, this is mostly useful for reading and writing various mDNS requests that they don't support, since, well, they tend not to support them.  That's what I use it for, anyway.  It can also be used to just play with DNS messages more generally, see what's actually being tossed about.



## Useful Links

- [RFC 1035](https://tools.ietf.org/html/rfc1035.html)
