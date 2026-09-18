# 03: Sprites obey walls, ledges and each other

**What to build:** The populated level's static sprites participate in Doom's visibility rules. The BSP walk gathers each visible sector's things once, projects only those inside the view, sorts them back to front with vanilla's tie behavior, and clips them against wall silhouettes, floors and ceilings. Near sprites cover distant ones and nothing leaks through a wall or ledge.

**Blocked by:** 02 (The non-monster population spawns)

**Status:** ready-for-agent

- [ ] A sector split across several subsectors contributes each active thing once per frame
- [ ] Projection uses the existing 16.16 view transform, near-plane and side culls, patch offsets and reciprocal scale
- [ ] Sprite definitions support zero rotations and all eight rotated views, including mirrored lump names
- [ ] Visible sprites sort back to front with vanilla's equal-scale choice
- [ ] Stored wall silhouettes clip the correct top and bottom columns according to sprite height
- [ ] A solid wall fully hides a sprite behind it and a ledge clips only the hidden part
- [ ] Overlapping near and far sprites draw in the same order as Chocolate Doom
- [ ] Render cases for duplication, overlap, solid-wall hiding and ledge clipping pass on both lanes
- [ ] Every oracle case added here reports zero differing sprite pixels

