# 09: The exit ends the level, Space restarts

**What to build:** Special 11. The exit switch swaps its texture and marks the level ended at that tic; from then on the tic is the identity. The game holds the last frame, prints the level time in minutes and seconds to stdout once, and on Space or Enter builds a fresh state from the map as loaded and plays E1M1 again. Esc and Close still quit. The intermission is milestone 6's.

**Blocked by:** 06 (Switches)

**Status:** ready-for-agent

- [ ] A closed law on a literal level with an exit switch pins the ended flag, the tic it was set on, and that a further tic of any command changes nothing
- [ ] The frame after the exit shows the pressed switch
- [ ] The time printed is the clock over 35, as vanilla's tally shows it
- [ ] After a restart the state equals the state the game started with: a door opened before the exit is shut, a fired once-only line has its special back
- [ ] Checked in the window through the screenshot tool with a binary built to start beside an exit switch, or by a scripted run; how it was checked is recorded in the comments
- [ ] Both lanes pass; the flake check stays green
