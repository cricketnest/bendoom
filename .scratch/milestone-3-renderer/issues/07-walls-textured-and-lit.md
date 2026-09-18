# 07: Walls textured and lit as vanilla draws them

**What to build:** The wall columns become vanilla's. Each stored range selects its textures by side and pegging (upper, lower and one-sided middle; two-sided middle textures wait for ticket 09), its offset from the seg's offset plus the sidedef's, its texture mid from the pegging flags and the sidedef's row offset, and its light from the sector level with fake contrast for walls along an axis. Per column the texture column is the offset minus the tangent times the distance, the reciprocal scale is the 32-bit division, the light index is the scale shifted and capped, and the texel loop reads the fraction's top bits masked to 127 through the light's colormap. The render test's hash and samples update, and it gains frames at hand-chosen positions: a lit and a dark sector, a step and a lowered ceiling.

**Blocked by:** 04 (Textures compose from patches), 06 (Walls drawn in perspective)

**Status:** ready-for-agent

- [ ] One-sided walls, upper and lower textures draw with vanilla's pegging and offsets, seen in the window against Chocolate Doom by eye
- [ ] Walls dim with distance through the scaled-light table, sectors' light levels apply, and axis-aligned walls carry fake contrast
- [ ] Closed laws pin the texture column, the reciprocal scale and the light index cap at known inputs
- [ ] The render test's frames at the start and the chosen positions are pinned to Freedoom, pass on both lanes, and the flake check stays green

## Comments

In progress; paused mid-ticket with the tree green (all tests on both lanes, all terms check).

Built so far: `Draw.column` is `R_DrawColumn` (the texel at the fraction's whole part wrapped to 128 rows, through the colormap, the fraction stepped a row), on `Draw.each`. `Segs.geo` works out a range's normal, distance, texture offset (the first vertex's distance along the wall plus the side's and the seg's offsets) and centre angle; `Segs.rw` pegs the three textures by the line's flags and the side's row offset and carries the light number with fake contrast; `Segs.col.draw` derives each column's texture column, colormap (the scale's light index capped at 47) and reciprocal scale, and draws the one-sided, upper and lower walls through `Gfx.column`. The closed law `wall_column` pins the texture column at the centre and at column 0's angle (63 and -97, the shift flooring the negative), the reciprocal scale at 1, 64 and 1/256, and the colormap at light 8 for scale 1 and the capped scale 64; each number computed by hand, and the checker agreed. In the window the start matches Chocolate Doom's by eye: the bookshelves, the hazard-striped gate, the crates, the grid wall. `tools/frame.bend` (ticket 10's frame dump, written early to choose positions) prints a frame as hex rows from `FRAME="x y degrees"`. The render test's start frame is re-pinned.

Left to do: add the render test's hand-chosen frames and pin them. Candidates already rendered and looked at: `137 256 45` (computer panels over the hazard-striped step), `488 256 0` (the railed pit under the ledge, a lower and darker sector), `-416 256 180` (the start looking west at a wall with a lowered opening). A lit against a dark sector still wants choosing from the sectors' light levels. Then tick the boxes and resolve.
