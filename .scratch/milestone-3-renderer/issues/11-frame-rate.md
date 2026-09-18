# 11: At least 35 frames a second

**What to build:** The game plays at Doom's speed with everything drawn. The frame rate is measured in the window on the dev machine at the start and while walking E1M1's opening rooms. If it is under 35, the renderer is restructured until it holds: independent column ranges that each compute vanilla's exact columns in parallel, a different data layout for texels and colormaps, a cheaper fold into the window's image. The render test's pinned hashes gate every change, so fidelity cannot slip. The numbers before and after, and what was changed, are recorded in the comments with the machine named.

**Blocked by:** 10 (Frames match Chocolate Doom pixel for pixel)

**Status:** resolved

- [x] Frames a second at the start and while walking are measured and recorded, with the method
- [x] The game holds at least 35 frames a second on the dev machine with walls, planes, the sky and masked textures drawn
- [x] Every render test frame keeps its pinned hash through the changes; both lanes pass and the flake check stays green

## Comments

Done. The game holds 39 frames a second at the start and 43 to 45 while running E1M1's opening rooms, in its 1280 by 960 window, with walls, planes, the sky and masked textures drawn. Every render test frame kept its pinned hash through every change; both lanes pass.

Method. `bench/window.bend` runs the game's own loop (now `src/game.bend`, which `doom.bend` and the bench share) for 600 frames in the game's window and prints frames over elapsed time; `WALK=1` holds run and up, so the player runs east from the start, down the step and off the ledge into the pit. Machine: x86_64 benchmark host, native build. The window was opened on a headless X server (Xvfb), not the desktop, so the numbers include the runtime's fill of the 1280 by 960 image and the X put, but no compositor; this kept automated measurements off the desktop.

| | at rest | walking |
| --- | --- | --- |
| before, 12 threads | 27 to 28 | 35 to 36 |
| before, 1 thread | 33 | |
| after, 12 threads | 36 | 44 |
| after, 1 thread | 39 | 43 to 45 |

Where a frame's 36 ms went, measured piece by piece on one thread: the runtime's `Window.frame` about 19 ms, the render 8.5 ms, the fold into the image 2.2 ms, and the rest in dropping the image. The 19 ms are not ours: the runtime fills the window by walking the image quadtree from its root once for every one of the 1.23 million window pixels, nine levels each. That bounds the game near 50 frames a second at this window size whatever the renderer costs, and leaves it under 10 ms to make 35.

What changed, each measured:

- The explicit `Image.drop` after each frame is gone. It forks its work across the runtime's threads, which cost more than it saved: without it the window went from 27 to 31 frames a second on 12 threads and the process from 312 MB to 165 MB, flat over time, so nothing leaks.
- The seg loop looked up three texture columns a column whether or not a wall was drawn. A range now looks up where its textures' columns start once, and a wall's column only when the column has that wall: render 8.5 to 6.6 ms.
- The masked pass worked out every stored range's texture, pegging and light before finding it had no masked columns. It now passes such a range over first: render 6.6 to 5.5 ms.
- The package's wrapper runs the game with `--threads 1`. The game makes no parallel call, and the runtime's idle workers cost three frames a second.
- The column step was re-derived as one def over a flat range record (no plan record, no boxed texture and geometry records). It removed two types and several accessors and changed no frame; it did not change the time either, so it stays as the simpler shape, not as an optimisation.

What I learned about the cost model, for whoever optimises next: a lookup in a small `Vec` is about 15 ns (the 350 ns of ticket 06's bench was cache misses in a two-million-entry tree), and a pixel costs about 25 ns, so neither is the render's cost. perf puts half the BSP walk in the runtime's `term_drop` and a fifth in `span_fade`, its reference counting: destructuring an owned record that is still shared bumps every boxed field and drops the unused ones. Its symbols for our own defs are unreliable, since the generated code is inlined. The render is now 5.5 ms of a 26 ms frame; the next real gain is in the runtime's window fill, not here.

`bench/frames.bend`: a hundred headless frames, render and fold, 1.05 s with the load on one thread, about 9 ms a frame.
