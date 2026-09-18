# 13: The frame rate holds, the README says what was built

**What to build:** The milestone closed. The frame rate is measured in the window on the dev machine with a door moving and the lights and animations running, by the window bench driven with a script that uses the first door, and recorded with the machine named. The bar is milestone 3's 35 frames a second. The README's milestone 4 line is rewritten to name the lights, animations and scrolling walls, and marked done. Then the last pass the erasure rules ask for: what this milestone made obsolete and whether it is gone.

**Blocked by:** 10 (Lights blink, strobe and glow), 11 (Animations and scrolling walls), 12 (E1M1 from start to exit)

**Status:** ready-for-agent

- [x] Frames per second with a mover running recorded in the comments, beside milestone 3's number for the still level, machine and power state named; under 35 is a bug to fix here, not to note
- [x] The README's milestone 4 line names what was built and says done
- [x] No comment in the sim, the level, the renderer or the tools describes the level as unchanging, keys as the sim's input, or specials as unread
- [x] Every oracle count recorded in tickets 02 to 12 is zero or has its cause written beside it
- [ ] The spec's status line says done
- [x] The flake check is green

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

**The code review** (`/code-review` since `cecf33f`, a standards and a spec reviewer in parallel). The spec reviewer found the sim vanilla's in tic order, `T_MovePlane`, the door, lift and floor timings, the crush paths, use, the triggers, the lights, the animation phase and the exit clock. Fixed from the two reports:

- Special 48 scrolled both sides of its line; vanilla's `P_UpdateSpecials` moves `sidenum[0]` alone. The shareware map's eight are two-sided. `Level.seg.scroll` now asks the seg's side; the pedestal still reports 0 at 21 and 27 tics.
- The spec's closed law on special 23's destination was missing; `floor_lowered` pins it on the switched literal level (`Closed.switched(special)`, which the lift law now shares): -1 after tic 1, -32 after tic 32, both thinkers gone on tic 33, the door sector landing at once, the special gone.
- `Sim.use.insert` recursed through a `Bool.pick` on both arms, the same trap as the frame rate's; it takes whether the meet goes first as a parameter now.
- Three unused imports; the side textures built twice at load; `Vec.set`'s comment, which now says a leaf standing for many indices takes the value for all of them; the sim and render tests' headers, which restated the tickets' numbers and are now a paragraph each.

Left, with the reason:

- The random index starts at 1, not the spec's 0: 1 is vanilla's once it has spawned the player (ticket 10).
- Buttons count down among the thinkers, not after them; no thinker reads a side texture, so the order cannot be seen (ticket 08).
- A door's way down is fixed when it starts, where vanilla reads the sector's floor each tic; no floor under a door moves in either E1M1, so the two cannot differ on them, and a map where they would is a map with a mover no E1M1 carries.
- A second use on an open-and-stay door that sends it down, and the switch slot order when a side names two switches, differ from vanilla only where neither map goes (tickets 04 and 06).
- The repeatable switch's button is pinned by `lift_timeline` and not the sim test, since Freedoom's special 62 lines name no switch texture.
- The route is its own test file rather than lines of the sim test: 585 tics of one script read better alone.
- The smells the standards reviewer named as judgement calls (the mover's fields threaded as parameters, the Geo record spelled in every accessor, the test helpers repeated across test files, the closed laws' repeated setups) are the shapes `docs/bend.md` pushes toward: a record opened in the def that uses it, no shared test module the flake's test runner would build as a test. None hides a branch.
