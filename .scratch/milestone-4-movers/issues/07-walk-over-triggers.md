# 07: Walk-over triggers

**What to build:** Lines that fire when crossed. As P_TryMove does, after a move is taken each special line the player's box crossed is tested, newest first, and fires when the player's side of it changed. A once-only line's special is cleared when it fires. Special 2 starts an open-and-stay door on every tagged sector with no thinker: up to 4 under the lowest neighbouring ceiling, where the thinker ends. Special 36 starts a fast floor: down at 4 a tic to the highest neighbouring floor, plus 8 when that is not its own height. Only the shareware map carries 36, so its numbers are pinned by a closed law and checked once by the oracle on the shareware WAD.

**Blocked by:** 04 (Space opens a door)

**Status:** ready-for-agent

- [ ] The sim test crosses one of Freedoom's special 2 lines and prints the tagged door opening and staying open, heights and tics computed by hand from the WAD first
- [ ] Crossing the line again, either way, starts nothing
- [ ] A move that touches a special line without changing sides fires nothing; pinned in the sim test or by a closed law
- [ ] A closed law on a literal level pins special 36: the destination with and without the 8, and the speed
- [ ] The oracle compares a frame of an opened special 2 door on Freedoom and of the lowered floor on shareware, counts recorded, target zero
- [ ] The trigger fires from the move that crossed it, inside the tic's movement, so the mover starts on vanilla's tic; the oracle frame one tic after a crossing confirms it
- [ ] Both lanes pass; the flake check stays green
