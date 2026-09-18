# 08: Floors, ceilings and the sky

**What to build:** The rest of the frame. The seg loop marks the floor and ceiling visplanes of each column as vanilla marks them; subsectors find or split their planes by height, flat and light. After the walk the planes are drawn: sky planes as columns of the sky texture indexed by the view angle at vanilla's sky shift, never lit; flat planes as spans with the distance from the row slope, the steps and the start from the view angle at the span's first column, the light from the plane-light table by the distance shifted and capped, and the texel by the 64 by 64 wrap. The placeholder index from ticket 06 goes. The render test gains a frame with the sky in view.

**Blocked by:** 07 (Walls textured and lit)

**Status:** ready-for-agent

- [ ] Floors and ceilings draw in their flats, lit by distance and sector level; the sky shows through sky ceilings and pans at vanilla's rate as the player turns
- [ ] Visplanes have no static limit and split as vanilla's check does when a column range is already used
- [ ] Every pixel of the view is written at every render test position
- [ ] Closed laws pin the sky column for a known view angle and column, the plane light cap, and a span's start and step at known inputs
- [ ] The render test's frames are pinned to Freedoom, pass on both lanes, and the flake check stays green
