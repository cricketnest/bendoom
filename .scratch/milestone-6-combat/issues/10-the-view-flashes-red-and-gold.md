# 10: The view flashes red and gold

**What to build:** The palette flashes. The frame's output carries which of the WAD's 14 palettes is in force, chosen as `ST_doPaletteStuff` chooses: red by the damage count, red by the berserk fade, gold by the bonus count. The window, the film and the oracle read it.

**Blocked by:** 09 (The nukage hurts and the player dies)

**Status:** ready-for-agent

- [ ] The palette number is part of what the renderer answers, and the window's fold and the film read the chosen palette of PLAYPAL
- [ ] The oracle compares the palette its screenshot carries
- [ ] A closed law pins the palette for damage counts and bonus counts at each step's edge
- [ ] Render cases: a red frame after nukage damage and a gold one on a pickup's tic, at zero differing pixels and the same palette
- [ ] Neither map spawns a radiation suit, so the green palette has no code
