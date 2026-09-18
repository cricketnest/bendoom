# 12: E1M1 from start to exit

**What to build:** The milestone's claim as a test. A command script walks Freedoom's E1M1 from the player 1 start to the exit switch and presses it, with no key, through whatever doors, lifts and switches the route needs. It is written as runs in demo units against the sim's printed positions, the way the earlier walks were found, so the oracle can play the same script. The sim test runs it and prints the player at the route's landmarks and the tic the level ended on. The oracle checks the end against vanilla: paused one tic before the exit Chocolate Doom still shows the level, and one tic after it has left it. The shareware map gets a route of its own, run locally on the shareware WAD and recorded in the comments, since the unfree WAD stays out of the flake check.

**Blocked by:** 08 (The lift), 09 (The exit ends the level, Space restarts)

**Status:** ready-for-agent

- [ ] The sim test's route ends Freedoom's E1M1, and prints the ending tic and the time as minutes and seconds
- [ ] The oracle frame one tic before the exit reports its differing-pixel count, target zero; one tic after, Chocolate Doom's shot is no longer the level; both recorded
- [ ] Oracle frames at three landmarks along the route are compared, counts recorded, target zero; a difference far into the route is a desync to find, not to mask
- [ ] The shareware route's script, its ending tic and the same before-and-after check are recorded in the comments
- [ ] The route's JS lane run stays inside the recursion depth the Bend constraints name
- [ ] The maintainer plays both maps to the exit in the window once; the ticket stays open until the comments say so
- [ ] Both lanes pass; the flake check stays green
