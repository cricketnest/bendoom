# 08: Floors, ceilings and the sky

**What to build:** The rest of the frame. The seg loop marks the floor and ceiling visplanes of each column as vanilla marks them; subsectors find or split their planes by height, flat and light. After the walk the planes are drawn: sky planes as columns of the sky texture indexed by the view angle at vanilla's sky shift, never lit; flat planes as spans with the distance from the row slope, the steps and the start from the view angle at the span's first column, the light from the plane-light table by the distance shifted and capped, and the texel by the 64 by 64 wrap. The placeholder index from ticket 06 goes. The render test gains a frame with the sky in view.

**Blocked by:** 07 (Walls textured and lit)

**Status:** resolved

- [x] Floors and ceilings draw in their flats, lit by distance and sector level; the sky shows through sky ceilings and pans at vanilla's rate as the player turns
- [x] Visplanes have no static limit and split as vanilla's check does when a column range is already used
- [x] Every pixel of the view is written at every render test position
- [x] Closed laws pin the sky column for a known view angle and column, the plane light cap, and a span's start and step at known inputs
- [x] The render test's frames are pinned to Freedoom, pass on both lanes, and the flake check stays green

## Comments

Done. `src/planes.bend`. The visplanes' heads (height, flat, light, first and last column) are a pure list in the order they were made, which `R_FindPlane`'s first match and the split rule depend on; their columns are 1024 slots a plane (top at x + 1, bottom at x + 513, a top of 255 for a column not marked, as vanilla's 0xff) in an array of their own that starts with room for vanilla's 128 planes and doubles when it fills, so there is no limit. `R_Subsector` claims the floor's plane when the eye is above it and the ceiling's when below it or it is the sky, all sky planes being one; `R_StoreWallRange` checks the ceiling's plane and then the floor's before it marks them, growing the plane to the union when none of the range's columns it already spans is marked and making a new plane like it otherwise; the seg loop writes the marks (to a slot no plane uses when there is nothing to mark, which spares the loop a branch).

After the walk each plane is drawn in the order it was made. A sky plane is columns of the sky texture at the view angle shifted by 22, row 100 at the view's centre, one texel a row, through colormap 0. A flat plane's columns are walked left to right to one past its last, and `R_MakeSpans`' four while loops are four row ranges: the rows only the column before holds close, from its top and from its bottom, each drawn from where it opened (`spanstart`, in the main array) to the column before; the rows only this column holds open here. `R_MapPlane` gives a span its start through the view angle and distance scale of its first column, its steps from the frame's scales, and its colormap from the distance's light index capped at 127; `R_DrawSpan` is on `Draw.each`, like the columns. A span's pixels depend on where the span starts, so the planes had to be vanilla's for the frame to be.

The blanking of the view is gone. The render test draws each frame twice, over a view blanked to 0 and to 255, and prints whether the hashes agree: every pixel of the view is written at every position. It gained the hall under a strip of sky (`3 256 0`); the start has sky in view too. The closed law `plane_span` pins the sky column (128 at column 0's angle, 256 more a quarter turn on), the plane light at index 12 and at the cap, the frame's scales looking east (0 and 409), and a span's start and steps at the centre row for a plane 41 under the eye; an independent script computed each number and corrected one slip in my hand arithmetic before the checker saw it. `bench/frames.bend`: a hundred frames with planes, 1.14 s with the load, about 10 ms a frame.
