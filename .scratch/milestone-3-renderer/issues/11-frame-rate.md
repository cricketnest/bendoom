# 11: At least 35 frames a second

**What to build:** The game plays at Doom's speed with everything drawn. The frame rate is measured in the window on the dev machine at the start and while walking E1M1's opening rooms. If it is under 35, the renderer is restructured until it holds: independent column ranges that each compute vanilla's exact columns in parallel, a different data layout for texels and colormaps, a cheaper fold into the window's image. The render test's pinned hashes gate every change, so fidelity cannot slip. The numbers before and after, and what was changed, are recorded in the comments with the machine named.

**Blocked by:** 10 (Frames match Chocolate Doom pixel for pixel)

**Status:** ready-for-agent

- [ ] Frames a second at the start and while walking are measured and recorded, with the method
- [ ] The game holds at least 35 frames a second on the dev machine with walls, planes, the sky and masked textures drawn
- [ ] Every render test frame keeps its pinned hash through the changes; both lanes pass and the flake check stays green
