# 25: Both routes survive, the frame rate holds, and milestone 6 closes

**What to build:** The measurement, the routes, the erasure pass and the README line that close the milestone.

**Blocked by:** 05 (Pickups and the locked door leave a message), 23 (The face), 24 (The long fight stays in step with Chocolate Doom)

**Status:** ready-for-agent

- [ ] The Freedoom route test reaches the exit and the intermission with monsters on, fighting or avoiding them, in the flake check; the shareware route is run by hand
- [x] The window holds 35 frames a second in Freedoom's first fight with the monsters awake; the ticket records the machine, the scene and the range
- [ ] `nix flake check` passes on both lanes, and the proof checks all terms
- [x] Ticket 03 made the wall and geometry laws hold by construction: `State.held` puts the geometry and the player's place back after every thinker's turn, at a measured 0.46 ms a tic before monsters. Measure it again with the monsters thinking; if it costs a frame a second, or if any thinker could rightly move the player, replace the clamp with a proof that each thinker kind keeps both
- [x] The erasure pass: every def is used; no current source or milestone summary describes the pre-combat game; the oracle holds no mask but the pause graphic's and the face's
- [x] The maintainer plays both maps with monsters to the intermission
- [ ] The README's milestone 6 line and the spec's status say done

## `State.held` measurement

The first-fight sound bench was built a second time with `State.held`
reduced to the identity, then the two binaries were alternated for three
600-frame runs apiece against the same real-rate sink. The checked build
took 10998, 11220 and 11046 ms (53–54 FPS); the identity build took 11439,
11206 and 11265 ms (52–53 FPS). Removing the clamp did not gain a frame per
second and was slightly slower in this sample. No thinker may rightly move
the player or mutate static geometry, so the cheaper and stronger choice is
to keep the construction that enforces both facts.

## Routes

The complete Freedoom demo in `tests/fixtures/freedoom.lmp` reaches the exit on tic 2060 with 25 health, 82 armour, random index 22, 11 of 29 kills, 11 of 49 items and no secrets. Chocolate Doom 3.1.1 reports the same exit fields. After 600 idle tics, its intermission shows 37% kills, 22% items, 0% secrets, 0:58 time and 0:30 par; the full frame comparison returns zero. `tests/route.bend` checks these results. The independent engine trace and frame report are in `/tmp/m6-routes/exit-trace/final.log` and `/tmp/m6-routes/full-exit-oracle.json`.

The shareware route also reaches the exit alive and its settled intermission frame returns zero. Its 650-command script and report are in `/tmp/m6-routes/shareware-fire.script` and `/tmp/m6-routes/shareware-tally.json`. Ticket 24 separately checks the longer combat state and intermediate frames on both WADs.

## Play-through

21 Sep 2026. The maintainer played both packages on `a3126db` with monsters to the intermission.
