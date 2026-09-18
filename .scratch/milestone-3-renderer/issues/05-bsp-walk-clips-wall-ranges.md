# 05: The BSP walk clips the view into wall ranges

**What to build:** The front half of vanilla's frame, without pixels: from an eye, the view tables (angle to column, column to angle, row slope, distance scale, scaled and plane light) computed at load with vanilla's formulas at 320 by 168, the BSP walked front to back with each node's box tested against the solid columns, each seg clipped by angle to the view and then against the solid-column list by the solid and pass-through rules, and each surviving range stored with its columns, its scale at the first column and its scale step. A test renders the start's ranges and prints them: seg number, first and last column, scale and step. The renderer's laws begin: the solid-column list stays sorted and disjoint after any clip, and closed laws pin the view tables and the scale from the global angle at inputs whose vanilla answers are known.

**Blocked by:** 02 (The player has an eye), 03 (The level carries what the renderer reads)

**Status:** ready-for-agent

- [ ] The view tables match vanilla's at pinned entries: the edge columns' angles, the centre row's slope, the first and last scaled-light rows
- [ ] The walk visits subsectors front to back and skips nodes whose box is fully hidden, as vanilla's box test does
- [ ] Clipping keeps the solid-column list sorted and disjoint; stated universally and proven by induction over the list
- [ ] The scale from the global angle keeps vanilla's overflow guard and clamps; pinned by closed laws
- [ ] No static limit: the list of ranges and the solid-column list grow as needed
- [ ] The test prints the start's ranges pinned to Freedoom, passes on both lanes, and the flake check stays green
