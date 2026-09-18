# 07: Walls textured and lit as vanilla draws them

**What to build:** The wall columns become vanilla's. Each stored range selects its textures by side and pegging (upper, lower and one-sided middle; two-sided middle textures wait for ticket 09), its offset from the seg's offset plus the sidedef's, its texture mid from the pegging flags and the sidedef's row offset, and its light from the sector level with fake contrast for walls along an axis. Per column the texture column is the offset minus the tangent times the distance, the reciprocal scale is the 32-bit division, the light index is the scale shifted and capped, and the texel loop reads the fraction's top bits masked to 127 through the light's colormap. The render test's hash and samples update, and it gains frames at hand-chosen positions: a lit and a dark sector, a step and a lowered ceiling.

**Blocked by:** 04 (Textures compose from patches), 06 (Walls drawn in perspective)

**Status:** resolved

- [x] One-sided walls, upper and lower textures draw with vanilla's pegging and offsets, seen in the window against Chocolate Doom by eye
- [x] Walls dim with distance through the scaled-light table, sectors' light levels apply, and axis-aligned walls carry fake contrast
- [x] Closed laws pin the texture column, the reciprocal scale and the light index cap at known inputs
- [x] The render test's frames at the start and the chosen positions are pinned to Freedoom, pass on both lanes, and the flake check stays green

## Comments

Done. `Draw.column` is `R_DrawColumn` (the texel at the fraction's whole part wrapped to 128 rows, through the colormap, the fraction stepped a row), on `Draw.each`. `Segs.geo` works out a range's normal, distance, texture offset (the first vertex's distance along the wall plus the side's and the seg's offsets) and centre angle; `Segs.rw` pegs the three textures by the line's flags and the side's row offset and carries the light number with fake contrast; `Segs.col.draw` derives each column's texture column, colormap (the scale's light index capped at 47) and reciprocal scale, and draws the one-sided, upper and lower walls through `Gfx.column`. The closed law `wall_column` pins the texture column at the centre and at column 0's angle (63 and -97, the shift flooring the negative), the reciprocal scale at 1, 64 and 1/256, and the colormap at light 8 for scale 1 and the capped scale 64; each number computed by hand, and the checker agreed. In the window the start matches Chocolate Doom's by eye: the bookshelves, the hazard-striped gate, the crates, the grid wall. `tools/frame.bend` (ticket 10's frame dump, written early to choose positions) prints a frame as hex rows from `FRAME="x y degrees"`. The render test's start frame is re-pinned.

The render test gained four hand-chosen frames, each with the eye at rest on the floor and the angle a multiple of 45 degrees so Chocolate Doom can stand in the same spot: a bright metal wall (`736 464 135`), the dim bench room north of the start (`-416 256 90`), the hazard-striped step under the computer panels (`137 256 45`) and the lowered opening west of the start (`-416 256 180`). Each was rendered through `tools/frame.bend` and looked at before it was pinned, and the step frame's hash was recomputed from the dump by an independent script, which agreed. Pinned to Freedoom, passing on both lanes.
