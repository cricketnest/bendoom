# 02: The player has an eye: height, bob, dips and the fall

**What to build:** The vertical axis of vanilla's player, so that the renderer has an eye to draw from. The player gains a height above the floor, a vertical momentum, a view height and its delta. Each tic, after the XY move, the vertical move runs as vanilla's does: gravity when above the floor (double on the first airborne tic, single after), the clamp to the floor with the landing dip, and the step-up dip when the floor rises under the player. The eye is then computed as vanilla computes it: the bob from the squared momentum capped at the maximum, the view height ramping back to its rest, the eye bounded by the ceiling. The XY move's step-up rule now measures from the player's height, not its floor. The sim test prints the eye's height above the floor after each run, and its script walks off a ledge.

**Blocked by:** 01 (The repo holds no Python)

**Status:** resolved

- [x] The player record carries height, vertical momentum, view height and its delta; every existing law still proves with the new fields
- [x] Walking off a ledge falls at vanilla's gravity and lands with vanilla's dip; the sim test's script includes one and pins the heights
- [x] Standing still on the floor puts the eye 41 above it; stated as a universal law over positions and proven
- [x] Closed laws on a literal level pin the first and second airborne tics, the landing dip, the bob at running speed and its cap, and the step-up dip, each against a number computed by hand from vanilla's formulas and noted in the comments
- [x] The wall law and replay composition still prove; the test passes on both lanes and the flake check stays green

## Comments

Done. The player record carries z, momz, ceilz, viewheight, deltaview, viewz and tic (Doom's leveltime, the bob's clock) beside what it had. A tic runs in vanilla's order: the command, `Sim.move` (thrust only on the ground), `Sim.eye` (P_CalcHeight, from the momentum after the thrust and the height before the move), `Sim.xy` (no friction in the air; the step-up and headroom rules measure from z, and a taken move keeps the ceiling as well as the floor), `Sim.z` (P_ZMovement: the step-up dip, double gravity on the first airborne tic, the landing dip past 8 a tic, the ceiling), then the clock.

The sim test prints z and the eye above the floor, and a second walk runs east from the start off the 140-unit ledge at x = 192 (the only drop past 35 units reachable from Freedoom's start without a door): the last tic on the ledge, the first airborne tic (momz -2, z unmoved), the second (z 10, momz -3), the landing sixteen tics on at 17 a tic, the dip of -2.125 it sets, and the view back at 41 forty tics later. The first walk's lines match milestone 2's up to the first drop, after which the airborne tics (no thrust, no friction) shift the path by a tenth of a unit. Both lanes agree; the values are regression values, since the vertical movement has no oracle.

Laws: `tic_rest` now states the position is kept, for any level and position; a whole-record equation no longer computes for a universal level, because the eye multiplies the bob (zero at rest) by a sine read from the level's table, and the checker cannot multiply by a symbolic word. Its floor is the literal 0 for the same reason: `z <= floorz` on a symbolic word is stuck. `eye_rest` (universal over positions) and the closed laws `tic_from_rest`, `fall_gravity`, `landing_dip` (9 a tic dips, 8 does not), `bob_run_and_cap` and `step_up_dip` stand on `Level.room`, a literal one-sector level that also replaced the loader's malformed-WAD fallback; each number was computed by hand from vanilla's formulas (the derivation is in the law's comment) and the checker agreed on the first run. The wall law's lemmas grew `eye_free`, `z_free` and `clock_free`, and `pick_free`'s field-by-field statement gave way to a flag lemma per pick. `bend PROOF.bend`: all terms check.
