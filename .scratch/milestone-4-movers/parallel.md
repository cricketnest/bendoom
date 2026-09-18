# Milestone 4 in parallel: what an agent taking one ticket needs to know

Tickets 01 to 06 are resolved on `main`; their `## Comments` say what exists and why. The main session keeps 07, 08, 12 and 13, which depend on each other. Tickets 09, 10 and 11 are free to take, one agent each. Deleted when the milestone closes.

## How to work

- Read `AGENTS.md` (the erasure rules bind), `docs/bend.md`, the spec, your ticket, and the comments of tickets 02 to 06.
- Work in your own git worktree on a branch `m4-ticket-NN` cut from `main`. Commit there with a conventional message ending in the `Co-Authored-By` line the earlier commits carry. Do not push, do not merge; rebase on `main` before you finish and say in your last message what conflicted. The main session merges.
- Other agents edit `src/sim.bend`, `LAWS.bend`, `PROOF.bend`, `tests/sim.bend` and `tests/render.bend` at the same time. Add new sections; do not reorder, reformat or rename what is there. In tests, add your lines at the end of the run list, before `end`.
- Expected values come from outside the code first: `source tools/wad.nu` in nushell gives the map's lines, sides, sectors and vertices as tables; vanilla's constants come from linuxdoom-1.10's source. Write them into your ticket's `## Comments` before the Bend code answers, then record what the code printed.
- No Python. Scripts are nushell; anything that calls game code is Bend.
- Mark your ticket's boxes, set `**Status:** resolved`, and write its comments as the resolved tickets do: what was built, where it differs from the ticket's words and why, every oracle count.

## Commands

Everything runs inside the dev shell, with the AppImage's library path dropped:

    nix develop -c bash -c 'unset LD_LIBRARY_PATH; bend PROOF.bend 2>&1 | tail -30 | cut -c1-400'   # about 40 s; "All terms check."
    nix develop -c bash -c 'unset LD_LIBRARY_PATH; rm -f /tmp/t; bend tests/sim.bend -o /tmp/t && /tmp/t'       # native lane
    nix develop -c bash -c 'unset LD_LIBRARY_PATH; bend tests/sim.bend -o /tmp/t.js && bun /tmp/t.js'            # JS lane

A test passes when its output equals its trailing `#|` lines on both lanes (`nix/tests.nix` is the rule). Remove the old binary before building: a failed build otherwise leaves the stale one to run and pass. Cut long error lines, a failed closed law prints the whole level.

The oracle (headless, about 10 s plus the script's length):

    nix develop -c bash -c 'unset LD_LIBRARY_PATH; bend tools/frame.bend -o /tmp/frame'
    nix develop -c nu -c 'hide-env --ignore-errors LD_LIBRARY_PATH; nu tools/oracle.nu 832 384 90 "20,0,0,0,0 20,25,0,0,0 1,0,0,0,1 20,0,0,0,0" --frame /tmp/frame'

A script is runs of `count,forward,side,turn,use` in a demo's units; the place is where the PWAD starts the player. `tools/walk.bend` prints where a script leaves the sim, run by run, with chosen sectors' heights (`FRAME`, `SCRIPT`, `SECTORS` in the environment); it is how runs are found.

## The shape of the sim

- `S.State{player, level, sidetex, thinkers, rnd, clock, ended, usedown}`. `L.Level{geo, sectors, specials}`: `Level.Geo` is what no tic writes. A tic writes through `Level.plane.put`, `Level.light.put`, `Level.special.put` and `V.Vec.set` on `sidetex`.
- `Sim.tic` runs the player (`Sim.move`, `Sim.eye`, `Sim.xy`, `Sim.z`), then `Sim.use` on the press, then `Sim.thinkers`, and packs its answer in `Sim.tic.kept` from the geometry it began with. Whatever a thinker does, only the sectors, the specials, the side textures, the thinkers, the random index and the ended flag come back, and of the player only its height, floor and ceiling. That is what keeps `tic_keeps_geometry` and the wall law one-line proofs: do not return anything else through it, and do not make `Sim.tic.kept` destructure the state it is given.
- `Thinker` is `Mover`, `Blink` or `Glow`. `Sim.think` has a case for each; `Sim.moving` and `Sim.door.turn` pass over whatever is no mover. `State.at` spawns the level's lights, so a Freedoom state starts with nine thinkers and the random index at 1.
- Use specials dispatch in `Sim.use.special`; tagged movers start through `Sim.tagged`, `Sim.start(~maker, ..)` and `Sim.use.once`.
- The closed laws' literal level is `Closed.doors()` in `LAWS.bend`, with `Closed.used`, `Closed.idled`, `Closed.moving`. A law that re-clips the player each tic is slow in the checker; keep such replays short.

## Bend, beyond docs/bend.md

- Constructor names are global across Base: `Move` clashed with the window's event.
- A let of a constructor needs its type: `+level = {L.Level{geo, sectors, specials} : L.Level}`.
- A match comes before any destructuring let of another parameter; destructure inside the cases.
- A `do` block's binds are affine: to use a state twice, pass it to a def whose parameter is `+s`.
- A pair `A & B` is not Data, so it cannot be a `+` parameter; pass its parts.
- A proof about a function that opens `Level{Geo{..}, ..}` must open the level too, even for the case that does not use it.
