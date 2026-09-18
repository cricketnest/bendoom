# 05: The BSP walk clips the view into wall ranges

**What to build:** The front half of vanilla's frame, without pixels: from an eye, the view tables (angle to column, column to angle, row slope, distance scale, scaled and plane light) computed at load with vanilla's formulas at 320 by 168, the BSP walked front to back with each node's box tested against the solid columns, each seg clipped by angle to the view and then against the solid-column list by the solid and pass-through rules, and each surviving range stored with its columns, its scale at the first column and its scale step. A test renders the start's ranges and prints them: seg number, first and last column, scale and step. The renderer's laws begin: the solid-column list stays sorted and disjoint after any clip, and closed laws pin the view tables and the scale from the global angle at inputs whose vanilla answers are known.

**Blocked by:** 02 (The player has an eye), 03 (The level carries what the renderer reads)

**Status:** resolved

- [x] The view tables match vanilla's at pinned entries: the edge columns' angles, the centre row's slope, the first and last scaled-light rows
- [x] The walk visits subsectors front to back and skips nodes whose box is fully hidden, as vanilla's box test does
- [x] Clipping keeps the solid-column list sorted and disjoint; stated universally and proven by induction over the list
- [x] The scale from the global angle keeps vanilla's overflow guard and clamps; pinned by closed laws
- [x] No static limit: the list of ranges and the solid-column list grow as needed
- [x] The test prints the start's ranges pinned to Freedoom, passes on both lanes, and the flake check stays green

## Comments

Done. Four new modules. `src/project.bend` holds the view tables at 320 by 168 by vanilla's formulas (the focal length, `viewangletox` with its fencepost pass, `xtoviewangle`, the row slopes, the column distance scales, `R_CheckBBox`'s corner table) and the view's geometry: `R_PointToAngle`, `R_PointToDist` with Chocolate Doom's guard for a point at the eye, `R_ScaleFromGlobalAngle` with its overflow guard and clamps, and the angle clipping `R_AddLine` and `R_CheckBBox` share, written once as `View.span`. The light tables are functions, not tables: `scalelight` and `zlight` are each a subtraction and a clamp. `xtoviewangle` is one sweep rather than vanilla's 321 scans, since the columns fall as the angle rises. `src/clip.bend` is the solid-column list, `src/draw.bend` the draw's state, `src/segs.bend` `R_AddLine` and the scale half of `R_StoreWallRange`, `src/bsp.bend` the walk: a stack of tasks in the state (visit a node, check a far child's box once the near side is drawn, add a seg) instead of vanilla's recursion, since Bend has no mutual recursion and every step reads the solid columns the last one left.

The solid columns are a sorted list of ranges on Nat columns with no sentinels: vanilla brackets its array with ranges off both screen edges to spare its loops the bounds checks, a list needs none, and the fragments come out the same. `Clip.add` is the list's half of `R_ClipSolidWallSegment`, `Clip.gaps` the fragments both clip functions hand to `R_StoreWallRange`, left to right, `Clip.covers` the list's half of `R_CheckBBox`. No list in the draw has a limit.

Laws. `solid_sorted` is universal and proven by induction over the list: clipping any range with first no more than last into any sorted list leaves a sorted list. Its lemmas are a small order library on `Nat.cmp` (`le_trans`, `le_lt_le`, `not_lt_le`, `le_max`, `min_le_max`), the head lemmas of both loops, and `absorb_sorted`; since a proof is an affine value, the sorted hypothesis is split once into its three conjuncts and the induction step is handed to the helper as a continuation. Closed laws: `solid_clips`, `view_edges` (the focal length 10477766 and the tangents landing on columns 1, 0, 320, 321 and 160, which makes column 0's angle fine angle 3073, Doom's clipangle 0x20080000), `view_sweep`, `view_rows`, `wall_scale` (1 at distance 160 at the centre and at the edge alike, the overflow guard, both clamps), `light_tables`. Every expected number was computed by hand and again by an independent script before the checker saw it, and the checker agreed with all of them. The whole tables are not sampled in a law: the checker needs 26 s to build them once (it did, and answered the clipangle), so the laws pin the per-entry functions and run the sweep on a five-entry list.

`tests/ranges.bend` prints the start frame's 129 ranges (vanilla's limit is 256) and the solid columns, which end as 0 to 319, as a closed map must leave them. Pinned to Freedoom, passing on both lanes; the values are regression values until ticket 10's oracle.
