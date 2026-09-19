# 12: E1M1 from start to exit

**What to build:** The milestone's claim as a test. A command script walks Freedoom's E1M1 from the player 1 start to the exit switch and presses it, with no key, through whatever doors, lifts and switches the route needs. It is written as runs in demo units against the sim's printed positions, the way the earlier walks were found, so the oracle can play the same script. The sim test runs it and prints the player at the route's landmarks and the tic the level ended on. The oracle checks the end against vanilla: paused one tic before the exit Chocolate Doom still shows the level, and one tic after it has left it. The shareware map gets a route of its own, run locally on the shareware WAD and recorded in the comments, since the unfree WAD stays out of the flake check.

**Blocked by:** 08 (The lift), 09 (The exit ends the level, Space restarts)

**Status:** resolved

- [x] The sim test's route ends Freedoom's E1M1, and prints the ending tic and the time as minutes and seconds
- [x] The oracle frame one tic before the exit reports its differing-pixel count, target zero; one tic after, Chocolate Doom's shot is no longer the level; both recorded
- [x] Oracle frames at three landmarks along the route are compared, counts recorded, target zero; a difference far into the route is a desync to find, not to mask
- [x] The shareware route's script, its ending tic and the same before-and-after check are recorded in the comments
- [x] The route's JS lane run stays inside the recursion depth the Bend constraints name
- [x] The maintainer plays both maps to the exit in the window once; the ticket stays open until the comments say so
- [x] Both lanes pass; the flake check stays green

## Comments

Both maps are finished by a script, with no key. The maintainer played both to the exit in the window on 2026-09-19, on milestone 5's build with their things present, and the flake check is green on both lanes at the merge that followed (`353fd64`).

**Freedoom.** From the player 1 start (`-416 256 0`), 585 tics, time 0:16:

    35,50,0,0,0 40,0,0,0,0 1,0,0,14,0 50,50,0,0,0 1,0,0,32,0 10,50,0,0,0 1,0,0,18,0 12,50,0,0,0 10,0,0,0,0 1,0,0,0,1 62,0,0,0,0 20,50,0,0,0 1,0,0,30,0 20,50,0,0,0 1,0,0,34,0 10,25,0,0,0 10,0,0,0,0 1,0,0,0,1 62,0,0,0,0 16,50,0,0,0 1,0,0,-64,0 40,50,0,0,0 1,0,0,64,0 36,50,0,0,0 12,0,0,0,0 1,0,0,64,0 22,50,0,0,0 10,0,0,0,0 1,0,0,0,1 36,0,0,0,0 8,50,0,0,0 22,0,0,0,0 1,0,0,-64,0 9,50,0,0,0 20,0,0,0,0 1,0,0,0,1 5,0,0,0,0

Legs: east over the lift's west line and down with it (tic 75); across the pit to the first door (160); through it (243); over the big room to the door in its west wall (285); through that, north over the special 2 line, and west along the north room (454); to the exit room's door (487); into the exit room (554); west to the exit switch (584); the use ends the level on tic 585. The route is its own test, `tests/route.bend`, which prints each leg's end, the tic the level ended on and `Time 0:16`. It passes on both lanes: the JS lane replays the 585 tics in one fold with no stack trouble, since each tic is a tail call in `Sim.replay`.

**Shareware.** From its player 1 start (`1056 -3616 90`), 645 tics, time 0:18, run with `tools/walk.bend` on the unfree WAD and kept out of the flake check:

    20,50,0,0,0 1,0,0,-16,0 70,50,0,0,0 8,50,0,0,0 1,0,0,-48,0 10,50,0,0,0 10,0,0,0,0 1,0,0,0,1 40,0,0,0,0 30,50,0,0,0 1,0,0,-32,0 40,50,0,0,0 1,0,0,56,0 10,50,0,0,0 1,0,0,-24,0 38,50,0,0,0 1,0,0,-60,0 70,50,0,0,0 1,0,0,-32,0 8,50,0,0,0 1,0,0,28,0 30,50,0,0,0 10,0,0,0,0 1,0,0,0,1 40,0,0,0,0 50,50,0,0,0 10,0,0,0,0 3,0,-40,0,0 20,0,0,0,0 10,25,0,0,0 10,0,0,0,0 1,0,0,0,1 40,0,0,0,0 17,25,0,0,0 15,0,0,0,0 1,0,0,-64,0 8,25,0,0,0 15,0,0,0,0 1,0,0,0,1 5,0,0,0,0

Legs: north and north-east to the computer room's door, opened (tic 121); through the room and out its east side; along the south wall into the zigzag room; south across it to the corridor (363); through the door there and over line 308, whose turbo floor lowers ahead (505); lined up with the exit door, opened, into the exit room; west to the switch, whose use ends the level on tic 645.

Oracle, one shot each. Freedoom's three landmarks idle first so that the water and nukage in view show the map's frame (ticket 11 is not merged yet); the idle moves nothing but the clock, and both sides run it.

| WAD | script | what | differing |
| --- | --- | --- | --- |
| Freedoom | 79 idle, route to tic 75 | at the lift's bottom | 0 (752 without the idle, all nukage) |
| | 6 idle, route to tic 243 | through the first door | 0 (96 without) |
| | 82 idle, route to tic 455 | the north room | 0 (2480 without) |
| | route to tic 584 | one tic before the exit | 0 |
| | route to tic 590 | after the exit | 49529: vanilla has left the level |
| shareware | route to tic 100 | the computer room's door | 0 |
| | route to tic 363 | the south corridor | 0 |
| | route to tic 505 | the lowered floor | 0 |
| | route to tic 644 | one tic before the exit | 0 |
| | route to tic 650 | after the exit | 48331: vanilla has left the level |

So both routes are vanilla's to the tic over their whole length: a desync anywhere before the end would show at the tic before the exit.

With ticket 11 merged the idle prefixes are no longer needed: the route cut at tics 75, 243 and 455, with no idle first, reports 0 differing at each.
