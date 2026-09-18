# 06: Walls drawn in perspective, the frame shown at 4:3

**What to build:** The first frame in the window. The seg loop walks each stored range's columns, clips each by the ceiling and floor clip arrays, computes the wall's top and bottom from the sector heights and the scale, and fills the column with one palette index chosen from the sector's light through the colormap, so walls read as shaded slabs. The frame is a flat array of palette indices, 320 by 200, the top 168 the view and the bottom 32 zero; it is folded into the window's image through the palette at four pixels a cell, in a 1280 by 960 window whose cell rows map to frame rows at five sixths, so the picture has Doom's 4:3 proportions. The top-down view is deleted; only its fold survives in the module that shows the frame. The frame is drawn from the latest tic's state with no interpolation. Before the seg loop is written, the column's cost is measured (texel, colormap and palette lookups through copyable trees against owned arrays threaded through the draw) and the data layout is chosen from the number, recorded in the comments. The render test begins: it prints a 32-bit hash of the view's indices and the indices at fixed pixels for the start frame.

**Blocked by:** 05 (The BSP walk clips the view into wall ranges)

**Status:** resolved

- [x] The window shows E1M1's walls in perspective from the player's eye, shaded by sector light, and turning and walking move the view at 35 tics a second
- [x] The window is 1280 by 960 with the frame stretched to 4:3 by nearest neighbour; the bottom 32 rows are black
- [x] A column draw changes no pixel outside its top and bottom rows; stated universally and proven
- [x] No hall of mirrors: every pixel of the view at the start is written (planes may be a placeholder index this ticket)
- [x] The top-down view module is gone; the screenshot tool still works at the new window size
- [x] The column cost measurement and the chosen data layout are recorded in the comments with the machine named
- [x] The render test prints the start frame's hash and sampled pixels pinned to Freedoom, passes on both lanes, and the flake check stays green

## Comments

Done. The measurement came first, in ticket 03, where the loaders needed it (`bench/lookup.bend`, x86_64 benchmark host, native, `--threads 1`, ten million random reads from 2^21 entries): a copyable `Vec` tree 3.2 to 4.0 s, about 350 ns a read; a linear array through a helper chain 0.012 s, about 1 ns. A frame makes some hundred thousand texel and colormap reads, so trees would cost more than the 28 ms a frame has, and arrays cost nothing to speak of. The layout chosen: everything a pixel touches (frame, clip arrays, palette, colormaps, flats, patches, composed columns) in one linear array threaded through the draw; everything read once a column or less (the level, the view tables, the texture directory) stays in copyable trees, which the draw takes by copy with no threading.

`R_StoreWallRange` now works out a range's rows (`Segs.rw`: the wall's top and bottom and the back sector's ceiling and floor as row fractions with their steps, the sky hack between two sky ceilings, which planes are marked, which of the side's three textures apply) and `R_RenderSegLoop` draws it (`Segs.col`): each column's rows held inside the ceiling and floor clips, a one-sided wall drawn whole and the column closed, else the upper and lower walls drawn and the clips narrowed as vanilla narrows them. A column's values are the range's plus the column's offset times the step, which in wrapping arithmetic is vanilla's running sum, so columns are independent. This ticket's walls are one palette index, grey 96 through the colormap of the sector's light with fake contrast at the range's first scale; the view is blanked to index 0 first, which stands in for the planes.

`Draw.each` is the loop under every column (and, later, span): a function at every index from a first, in order. The law `each_in_order` is universal and proven by induction: a checker riding the loop from i sees every index be the one expected and ends expecting n + i, for all n and i. A column's pixel function writes only the row its index names, so a column draw changes no pixel outside its top and bottom rows. The law is on the loop rather than on the array because the checker cannot compute an array read at a symbolic index, so no universal statement about the frame's contents computes.

`src/show.bend` keeps the old view's fold, now through the palette and at 4:3: a cell is four pixels a side and cell row r shows frame row 5r/6, 240 cell rows for the frame's 200, in a 1280 by 960 window. `src/view.bend` is deleted. The game holds the array in its state, which made `Game` a Type; `Render.frame` is a pure function of the tables, the level, the graphics, the player and the array. `tools/screenshot.nu` works unchanged at the new size: the start shows the gate and the corridor beyond it in perspective, and holding Up and Left walks and turns the view.

`tests/render.bend` prints the start frame's FNV-1a hash and four pixels, pinned to Freedoom, passing on both lanes. `bench/frames.bend` renders and folds a hundred frames without the window: 0.46 s with the load, about 3.5 ms a frame at this stage.
