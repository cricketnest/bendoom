# 06: Switches

**What to build:** A switch shows that it took. P_ChangeSwitchTexture with the shareware switch list: of the front side's top, middle and bottom textures, the one that is a switch swaps to its partner, written into the side texture numbers in the state. A once-only switch clears its line's special. A repeatable one starts a 35-tic timer, counted down after the movers each tic, that swaps the texture back. The loader composes the partner of every switch texture the map's sides name, so a swap never names a missing graphic. The first switched mover comes with it: special 23 starts T_MoveFloor on every tagged sector with no thinker, down at 1 a tic to the lowest neighbouring floor, through ticket 04's T_MovePlane.

**Blocked by:** 04 (Space opens a door)

**Status:** ready-for-agent

- [ ] The switch list is vanilla's episode 1 pairs, taken from linuxdoom's source
- [ ] The sim test uses Freedoom's special 23 switch and prints the three tagged floors reaching their destination, the height and the tic computed by hand from the WAD first
- [ ] A second use of that switch does nothing; a universal law states that a fired once-only line has no special afterwards, and it is proven
- [ ] A closed law pins the repeatable switch's timer: pressed at one tic, back 35 tics later
- [ ] The load test shows the partner textures composed; the count of extra textures is recorded in the comments
- [ ] The render test gains a frame of the pressed switch; the oracle compares it before and after the press, counts recorded, target zero
- [ ] Both lanes pass; the flake check stays green
