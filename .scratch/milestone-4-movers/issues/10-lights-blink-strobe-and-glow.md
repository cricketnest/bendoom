# 10: Lights blink, strobe and glow

**What to build:** E1M1's lights as p_lights.c runs them. Vanilla's 256-entry random table comes in as a chunked table like the others, its index in the state, 0 at the level's start. Building a state spawns a light thinker for each sector special in sector order, as P_SpawnSpecials does, and they run each tic after the player's movement and before the movers. Special 1 is the random blink: between the sector's light and the lowest neighbouring light, bright for 1 or 65 tics (vanilla masks the random byte with 64) and dark for 1 to 8. Special 12 is the slow strobe in sync: 35 dark, 5 bright, the dark level 0 when no neighbour is darker. Special 8 glows 8 a tic between the sector's light and the lowest neighbouring light. Each writes the sector's light in the state, which the renderer already reads. The oracle tool stops zeroing sector specials.

**Blocked by:** 02 (The oracle plays a demo), 03 (One state the tic maps)

**Status:** ready-for-agent

- [ ] The random table is taken from linuxdoom's source; closed laws pin its first entries and the first blink's first counts on a literal level
- [ ] Closed laws pin the strobe's timeline with and without a darker neighbour, and the glow turning at both ends
- [ ] The sim test prints the light of one blinking and one strobing Freedoom sector at chosen tics, computed by hand from the WAD and the table first
- [ ] The render test gains a frame of a blinking sector at its dark level
- [ ] The oracle, with sector specials left in the PWAD, reports zero at every rest position of the render test and at the new frame; the tool's zeroing of sector specials and the comment about it are deleted
- [ ] Glow exists only on the shareware map; the oracle compares one shareware frame of it, count recorded
- [ ] Both lanes pass; the flake check stays green
