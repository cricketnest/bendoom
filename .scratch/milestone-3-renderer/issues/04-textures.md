# 04: Textures compose from patches

**What to build:** The wall textures E1M1 names and the sky texture, composed as vanilla composes them. The patch names lump, both texture definition lumps when the second exists, and the patches those textures reference are read; each named texture becomes indexed column data: a single-patch texture keeps its patch's posts so transparency survives, a multi-patch texture is pasted column by column as vanilla's composite is. A dash is no texture; a name the WAD lacks fails the load. The test from ticket 03 grows to print a texture's width, height and patch count, a texel from a multi-patch texture, and the first post of a masked single-patch texture.

**Blocked by:** 03 (The level carries what the renderer reads)

**Status:** ready-for-agent

- [ ] Every texture named by E1M1's sidedefs and the sky texture are composed at load; the other 800 stay directory entries and the start is not stalled
- [ ] A multi-patch texture's texels equal vanilla's composite; a single-patch texture keeps its posts
- [ ] The texture's width mask and height are kept for column wrap and the 128-row texel loop
- [ ] A missing texture name fails the load with the name; a dash resolves to no texture
- [ ] The test prints its samples pinned to Freedoom, passes on both lanes, and the flake check stays green
