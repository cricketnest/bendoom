# 03: The level carries what the renderer reads; the palette, colormaps and flats load

**What to build:** Everything vanilla's renderer reads from the map and the WAD except textures. The level record grows per seg its ends, lump angle, offset, linedef and side; per subsector its seg count and first seg; per node its two bounding boxes; per sector its floor and ceiling flat names and light level; per sidedef its offsets and three texture names. A byte reader joins the 16-bit one so byte lumps load: the first palette, the 34 colormaps, and the flats between the flat markers, of which only those E1M1's sectors name are kept as indexed data. The sky flat name marks a sky ceiling. A name the WAD lacks fails the load. A test loads through the game's loader and prints samples: a seg's angle and offset, a node's box, a sector's flats and light, a sidedef's textures, a palette entry, a colormap entry and a flat texel.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] The level record holds the seg, subsector, node box, sector and sidedef fields the renderer needs, read from the lumps as vanilla reads them, angles and offsets used as stored
- [x] The palette, the colormaps and E1M1's flats are loaded into indexed data; other flats stay directory entries
- [x] Names match as vanilla matches them: eight characters, case-insensitive; a missing flat name fails the load with the name
- [x] The test prints its samples pinned to Freedoom, passes on both lanes, and the flake check stays green
- [x] The sim test and the window are unchanged

## Comments

Done. The level record was re-derived rather than grown field by field: each lump is one tree of the 16-bit words kept of its records (a seg's six, a node's fourteen with both boxes, a sector's floor, ceiling and light, a side's two offsets and sector), indexed by record number times the record's words plus the field, so the record has fifteen fields where field-by-field growth would have made fifty. `Level.seg`, `Level.sub`, `Level.box`, `Level.sector` and `Level.side` answer what the renderer reads; the seg's angle and offset are the lump's, shifted to fixed point, and its back sector exists only behind a line flagged two-sided, as `P_LoadSegs` has it. The sides' three texture names and the sectors' two flat names are kept as the lumps spell them, upper-cased since Doom matches names without case. One generic reader, `Bytes.each`, does a read at each of a list of offsets planned purely by `Bytes.fields`; it replaced the 16-bit list and tree readers, and serves names and the tests' sample reads too.

`src/gfx.bend` is new. The bench this ticket's design rests on (`bench/lookup.bend`, x86_64 benchmark host, `--threads 1`, ten million random reads from 2^21 entries): a copyable `Vec` tree 3.2 to 4.0 s, about 350 ns a read; a linear array read through a helper chain 0.012 s, about 1 ns. So everything a pixel touches lives in one linear array the draw will thread: the frame and the clip arrays first, then the first palette as 0xRRGGBB words, the 34 colormaps, and the flats E1M1's sectors name (44 of Freedoom's 240), block-copied from the WAD's bytes, which are then dropped. `Gfx` is the Data directory into it: flat number to index, sector to floor and ceiling flat numbers, the sky flat's number. Lumps are found through a string map of the directory in which a later lump of a name replaces an earlier, as `W_CheckNumForName` searches from the end; a name the WAD lacks fails the load with Doom's message (`R_FlatNumForName: NOSUCH not found`, checked by a probe, since a test would need a broken WAD).

`tests/load.bend` prints two segs (one on a left side with a lump offset), a subsector, the root node's boxes, a sky and a plain sector with their flat names, two sides with their texture names, three palette entries, four colormap entries and two flats' texels. Every expected value was read from Freedoom's bytes in nushell before the loader existed, and the loader met all of them on its first run, on both lanes. The sim test's lines and the proofs are unchanged by the level's new shape; `Level.room` now takes map units.
