# 04: Textures compose from patches

**What to build:** The wall textures E1M1 names and the sky texture, composed as vanilla composes them. The patch names lump, both texture definition lumps when the second exists, and the patches those textures reference are read; each named texture becomes indexed column data: a single-patch texture keeps its patch's posts so transparency survives, a multi-patch texture is pasted column by column as vanilla's composite is. A dash is no texture; a name the WAD lacks fails the load. The test from ticket 03 grows to print a texture's width, height and patch count, a texel from a multi-patch texture, and the first post of a masked single-patch texture.

**Blocked by:** 03 (The level carries what the renderer reads)

**Status:** resolved

- [x] Every texture named by E1M1's sidedefs and the sky texture are composed at load; the other 800 stay directory entries and the start is not stalled
- [x] A multi-patch texture's texels equal vanilla's composite; a single-patch texture keeps its posts
- [x] The texture's width mask and height are kept for column wrap and the 128-row texel loop
- [x] A missing texture name fails the load with the name; a dash resolves to no texture
- [x] The test prints its samples pinned to Freedoom, passes on both lanes, and the flake check stays green

## Comments

Done. The texture half of `src/gfx.bend`. The reads are planned purely and run through `Bytes.each`: each texture lump's count, its definition offsets, the name at each (TEXTURE1's, then TEXTURE2's when the WAD has it); the sides' names and SKY1 numbered from 1 by first appearance, a dash being 0 and, as in Doom, so is whatever texture comes first in the WAD (AASTINKY exists because texture 0 is no texture); each wanted definition's width, height and patch count, then its patches' origins and patch numbers, then those patches' names from PNAMES, their lumps, widths and column offsets. A name missing from the definitions fails the load with `R_TextureNumForName: NAME not found`, a missing patch likewise.

The patches are copied whole into the array, each once however many textures use it, and a column is classified as `R_GenerateLookup` does: under one patch it is that patch's column in the copied lump, three past its first post's header, so the masked pass finds the posts where Doom finds them and a wall column reads the raw bytes Doom reads; under several it is composed as `R_GenerateComposite` does, each covering patch's posts pasted in order at the patch's row plus the post's, cut to the height, a post cut at the top keeping its first texels as Doom's memcpy does; under none it is 128 zeros. The composed columns of all textures lie end to end, each its texture's height, with 128 slots of slack after the last, since the texel loop reads up to row 127 whatever the height. 114 of Freedoom's 963 textures are composed; the native load of level and graphics takes 0.11 s.

`tests/load.bend` grew the width, height, patch count and mask of a ten-patch, a 72-tall and the sky texture, a side's three numbers, four texels of each of two multi-patch columns (COMPUTE1's ten patches, LITE3's sixty-four), three of a single-patch column and of the sky, and the first posts of two masked textures. The expected values came first, from nushell, which composed the multi-patch columns by vanilla's rule independently. The red run earned its keep: the numbering's seed had put a stray 0 at the head of the sides' numbers, shifting every side's textures by one, and the test named it at once. Both lanes pass.
