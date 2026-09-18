# 01: Bytes reads signed 16-bit values and lump records into arrays

**What to build:** Two readers the map lump parsers share, so that loading a lump is one call per lump. A signed 16-bit read that sign-extends into a U32 word, and a record-array read that walks a lump of fixed-stride records and lays one chosen field per record into a flat array indexed by record number. The WAD directory test still passes on both WADs.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [ ] A signed 16-bit read answers the two's complement word: 0xFFFF reads as the U32 for -1, 0x7FFF as 32767
- [x] A record-array read takes a lump's offset, record count, stride and field offset and answers an array with one U32 per record
- [x] Both follow the milestone 1 constraints: helpers before callers, no tuple pattern on a call result, shrinking count first in the recursion
- [ ] A law in LAWS.bend states sign extension for a negative and a positive sample; PROOF.bend proves it and the flake check stays green
- [x] The WAD directory test still answers its lines

## Comments

Done, with one cut. The record-array read is `Bytes.u16s` (one 16-bit field of every record, as a list) and `Bytes.vec` (the same as a tree indexed by record number), used by every map lump. No signed 16-bit read: the sign extension is shifted out by the conversion to fixed point (`w << 16` equals `sext16(w) << 16` modulo 2^32), and no other field is read as signed, so `Fixed.of_map` is the plain shift and the law `fixed_of_map` pins 0xFFFF to -1.0 and 0x7FFF to 32767.0 instead.
