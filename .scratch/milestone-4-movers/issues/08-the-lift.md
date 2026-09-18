# 08: The lift

**What to build:** The lift the player rides. Specials 62 (switch) and 88 (walk-over), both repeatable, start T_PlatRaise's down-wait-up-stay on every tagged sector with no thinker: down at 4 a tic to the lowest neighbouring floor no higher than its own, 105 tics of wait, up to the height it started at, then the thinker ends. The player on it rides through ticket 05's re-clip, the eye moving with the floor and no dip. A lift that rises into a player who does not fit goes back down and waits again. Special 62 swaps its switch and starts ticket 06's timer.

**Blocked by:** 05 (A moving plane re-clips the player), 06 (Switches), 07 (Walk-over triggers)

**Status:** ready-for-agent

- [ ] The sim test calls Freedoom's lift by its walk-over line, rides it down and up, and prints the floor, the player's height and the eye at chosen tics, all computed by hand from the WAD first
- [ ] The sim test calls it by its switch from below and prints the switch popping back 35 tics later
- [ ] A trigger on a running lift starts nothing; the lift answers again once its thinker has ended
- [ ] Closed laws on a literal level pin the lift's timeline (first tic, bottom, the tic it starts up, the top) and the crushed case going back down
- [ ] The oracle compares a frame from on the lift mid-travel and one at the bottom, counts recorded, target zero
- [ ] Both lanes pass; the flake check stays green
