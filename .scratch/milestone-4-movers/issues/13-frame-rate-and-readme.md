# 13: The frame rate holds, the README says what was built

**What to build:** The milestone closed. The frame rate is measured in the window on the dev machine with a door moving and the lights and animations running, by the window bench driven with a script that uses the first door, and recorded with the machine named. The bar is milestone 3's 35 frames a second. The README's milestone 4 line is rewritten to name the lights, animations and scrolling walls, and marked done. Then the last pass the erasure rules ask for: what this milestone made obsolete and whether it is gone.

**Blocked by:** 10 (Lights blink, strobe and glow), 11 (Animations and scrolling walls), 12 (E1M1 from start to exit)

**Status:** ready-for-agent

- [x] Frames per second with a mover running recorded in the comments, beside milestone 3's number for the still level, machine and power state named; under 35 is a bug to fix here, not to note
- [x] The README's milestone 4 line names what was built and says done
- [x] No comment in the sim, the level, the renderer or the tools describes the level as unchanging, keys as the sim's input, or specials as unread
- [x] Every oracle count recorded in tickets 02 to 12 is zero or has its cause written beside it
- [ ] The spec's status line says done
- [ ] The flake check is green

## Comments

**The frame rate was halved, and is back.** The window bench on Xvfb read 19 to 20 frames a second at rest where milestone 3's read 36 to 37 the same afternoon. A bench at each ticket's commit put the whole loss on ticket 10's merge (40 before, 20 after), yet the sim runs 700 tics in 9 ms and the renderer draws a lit state in 11 ms, as fast as an unlit one. perf found half the frame in reference-count drops under `Sim.around.go`: `Game.from` (ticket 09) chose between a fresh `State.start(level)` and the running state with `Bool.pick`, and a call is strict, so every frame built a fresh level start. Until ticket 10 that cost nothing; since then it spawns the nine lights, each scanning all 1175 lines for its neighbours. `Game.from` is now a `match`, and `docs/bend.md` says why a pick is no branch for a costly value. No other pick in the code builds anything costly.

Measured with `bench/window.bend` on Xvfb (the game's own loop, 600 frames, one thread as the package runs it), x86_64 benchmark host, on mains, `balanced` profile, `powersave` governor with `balance_performance`, three runs each:

| | at rest (the start) | the first door moving, lights running | circling (`WALK=1`) |
| --- | --- | --- | --- |
| milestone 3's binary, same session | 36, 37 | | |
| milestone 4, before the fix | 20, 20, 20 | 24, 24, 24 | |
| milestone 4 | 41, 38, 40 | 47, 48, 48 | 46, 46, 46 |

The door runs are the bench with `SCRIPT` set to the route's first 160 tics and a use (`35,50,0,0,0 40,0,0,0,0 1,0,0,14,0 50,50,0,0,0 1,0,0,32,0 10,50,0,0,0 1,0,0,18,0 12,50,0,0,0 10,0,0,0,0 1,0,0,0,1`): the 600 frames watch the door open, wait and start down while the pit's lights run. `Game.start` replays a script before its first frame to make that possible; the game passes none. Not measured on the desktop, to avoid interrupting the session: milestone 3 found the compositor costs 2 to 3 frames a second against Xvfb, so the start view should hold 35 there with a few to spare. That measurement goes with the play-through of ticket 12.

**The erasure pass.** Gone with the milestone: the sim's run of held keys (ticket 01), the Player's held count and clock, the level's sector heights in map units (fixed point once at load), `Level.cell`, the slide's own near test and hit (one `Sim.meets` for the slide and use), the door's separate turn helper, the oracle's eight shots, its PWAD writer and its zeroing of specials, the 57-tic idle, the frame dump's own script parsing (`tools/script.bend`, shared with the walk tool and the bench), the parallel-work note and the three agents' worktrees and branches. The comments that said geometry is never state, that the sim reads keys, or that Bendoom reads no specials and does not animate are rewritten or deleted; a search for them finds nothing stale.

**The oracle counts of tickets 02 to 12.** Every count is 0, or has its cause beside it and a 0 once the cause was gone: ticket 02's airborne and landing frames (the lift, 0 in ticket 08), ticket 05's 163 and ticket 07's 11312 (an animation's phase, 0 with the idle and 0 without it after ticket 11), ticket 12's route landmarks (0 without idles now), and the frames after the exit, where vanilla has left the level.

The spec's status stays open with ticket 12, which waits for the maintainer to play both maps to the exit in the window.
