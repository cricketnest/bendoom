# 03: The level carries what the renderer reads; the palette, colormaps and flats load

**What to build:** Everything vanilla's renderer reads from the map and the WAD except textures. The level record grows per seg its ends, lump angle, offset, linedef and side; per subsector its seg count and first seg; per node its two bounding boxes; per sector its floor and ceiling flat names and light level; per sidedef its offsets and three texture names. A byte reader joins the 16-bit one so byte lumps load: the first palette, the 34 colormaps, and the flats between the flat markers, of which only those E1M1's sectors name are kept as indexed data. The sky flat name marks a sky ceiling. A name the WAD lacks fails the load. A test loads through the game's loader and prints samples: a seg's angle and offset, a node's box, a sector's flats and light, a sidedef's textures, a palette entry, a colormap entry and a flat texel.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] The level record holds the seg, subsector, node box, sector and sidedef fields the renderer needs, read from the lumps as vanilla reads them, angles and offsets used as stored
- [ ] The palette, the colormaps and E1M1's flats are loaded into indexed data; other flats stay directory entries
- [ ] Names match as vanilla matches them: eight characters, case-insensitive; a missing flat name fails the load with the name
- [ ] The test prints its samples pinned to Freedoom, passes on both lanes, and the flake check stays green
- [ ] The sim test and the window are unchanged
