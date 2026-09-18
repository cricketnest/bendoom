# 06: Walls drawn in perspective, the frame shown at 4:3

**What to build:** The first frame in the window. The seg loop walks each stored range's columns, clips each by the ceiling and floor clip arrays, computes the wall's top and bottom from the sector heights and the scale, and fills the column with one palette index chosen from the sector's light through the colormap, so walls read as shaded slabs. The frame is a flat array of palette indices, 320 by 200, the top 168 the view and the bottom 32 zero; it is folded into the window's image through the palette at four pixels a cell, in a 1280 by 960 window whose cell rows map to frame rows at five sixths, so the picture has Doom's 4:3 proportions. The top-down view is deleted; only its fold survives in the module that shows the frame. The frame is drawn from the latest tic's state with no interpolation. Before the seg loop is written, the column's cost is measured (texel, colormap and palette lookups through copyable trees against owned arrays threaded through the draw) and the data layout is chosen from the number, recorded in the comments. The render test begins: it prints a 32-bit hash of the view's indices and the indices at fixed pixels for the start frame.

**Blocked by:** 05 (The BSP walk clips the view into wall ranges)

**Status:** ready-for-agent

- [ ] The window shows E1M1's walls in perspective from the player's eye, shaded by sector light, and turning and walking move the view at 35 tics a second
- [ ] The window is 1280 by 960 with the frame stretched to 4:3 by nearest neighbour; the bottom 32 rows are black
- [ ] A column draw changes no pixel outside its top and bottom rows; stated universally and proven
- [ ] No hall of mirrors: every pixel of the view at the start is written (planes may be a placeholder index this ticket)
- [ ] The top-down view module is gone; the screenshot tool still works at the new window size
- [ ] The column cost measurement and the chosen data layout are recorded in the comments with the machine named
- [ ] The render test prints the start frame's hash and sampled pixels pinned to Freedoom, passes on both lanes, and the flake check stays green
