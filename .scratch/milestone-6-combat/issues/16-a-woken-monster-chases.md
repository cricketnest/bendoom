# 16: A woken monster chases

**What to build:** A woken monster walks at the player with vanilla's movement: eight directions, turning toward its move direction, backing off and trying again when blocked, stopped by ledges too high, drops too deep and lines that block monsters, and opening the manual doors vanilla lets it open.

**Blocked by:** 03 (Things move, relink and spawn in play), 15 (A monster sees the player)

**Status:** resolved

- [x] `A_Chase`'s movement half, `P_NewChaseDir`, `P_TryWalk`, `P_Move` and `A_FaceTarget`, with every random draw in place, the active sound's among them
- [x] `P_TryMove`'s dropoff test: ticket 03's `Sim.check` does not gather `tmdropoffz`, so this ticket adds it to what the check answers
- [x] A blocked move uses the special lines it hit, which opens manual doors
- [x] Each monster moves at its speed on its move tics and relinks as it goes
- [x] The freedom law grows from the player to every thing that moved
- [x] Sim cases: a chase across a room, around a corner, through a door, and one stopped at a ledge, with places per tic and the random index from a replay of the source
- [x] The rest of ticket 08's ten pinned frames return to zero, or the ticket says which wait for an attack
- [x] tests/route.bend and tests/game.bend were routed around standing monsters by ticket 08; with monsters chasing, the route is derived again, and it may now have to wait for tickets 11 to 19 to fight its way through: if no route can reach the exit without fighting, say so and leave the route to ticket 25
- [x] A render case shows walking frames mid-chase at zero differing pixels, from a script that ends before any attack would start

## Comments

### What was built

- `A_Chase` is `Sim.chase` in `src/sim.bend`, the case `H.Chase{}` of `Sim.thing.act`. Its head counts the reaction time and the threshold down and turns the thing 45 degrees toward the direction it walks; then it gives up a target that can no longer be shot, holds its fire for a tic after an attack, fires where its type and range let it, and otherwise walks and calls out on a draw under 3.
- `P_NewChaseDir` is `Sim.chase.newdir`: the diagonal at the target first, then the two axis directions in the order the swap draw leaves them, then the direction already walked, then all eight in a drawn order, then the way it came, then nowhere. `P_TryWalk` is `Sim.chase.walk`, which draws the move count on a move that carried. `P_Move` is `Sim.chase.move`. `A_FaceTarget` is `Sim.chase.face`.
- `P_TryMove` for a thing that walks is `Sim.chase.step`. `Sim.Fit` gained a fourth field, `drop`, vanilla's `tmdropoffz`, narrowed at every opening the box crosses by `Sim.open_low`; `Sim.walks` is `Sim.passes` plus the ledge, and a thing with neither MF_DROPOFF nor MF_FLOAT, which is every monster either map spawns, has to pass it. The merged damage pass's `Sim.thing.fit`, which moves a thing a blow threw, now tests `Sim.walks` too, so a pushed thing stops at a ledge as vanilla's does; its note that the check did not gather the drop is gone with it.
- A blocked move presses the special lines its box reached, `Sim.spechit` gathering them as `PIT_CheckLine` does and `Sim.thing.uses` pressing them last first. `P_UseSpecialLine` for a thing that is not the player is special 1 alone, and never on a line marked ML_SECRET: each E1M1 has one such door. `Sim.door` gained a `shuts` flag, since bad guys never close doors. A move that is taken fires the walk-over specials it crossed, which for a thing is the lift's retrigger, special 88, alone.
- The counters live in the merged branch's mobj_t vector: the hunt adds `movedir` and `movecount` as slots 9 and 10 beside its target, reaction time and threshold, and `Sim.awake` is the one writer of the target a blow turns.

### Where each expected value came from

- Vanilla's source, Chocolate Doom 3.1.1: `p_enemy.c`'s `A_Chase`, `P_NewChaseDir` with its `opposite` and `diags` tables, `P_TryWalk`, `P_Move` with `xspeed` and `yspeed`, `A_FaceTarget` and `P_CheckMissileRange`; `p_map.c`'s `P_TryMove` and `PIT_CheckLine`; `p_switch.c`'s `P_UseSpecialLine`; `p_doors.c`'s `EV_VerticalDoor`; `p_spec.c`'s `P_CrossSpecialLine`; `info.c`'s speed, reactiontime, activesound and rows.
- The first move of the chase across the room was worked by hand before the code answered it: zombieman 177 at (752, 336) with the player at (488, 256) gives deltax -264 and deltay -80, so d1 is WEST, d2 is SOUTH and the diagonal is SOUTHWEST; the step is `8 * -47000`, so x becomes `752 * 65536 - 376000` = 48907072 and y `336 * 65536 - 376000` = 21644096. The test prints 746.262695 and 330.262695, which are those words exactly. The turn is the same reckoning: the facing of 180 degrees snapped to `7 << 29` is 0x80000000, the old movedir of 0 makes delta 0x80000000, which is negative as an `int`, so vanilla adds `ANG90/2` and the thing faces 225.
- The ledge is read from the WAD in nushell: shotgun guy 185 stands at (1104, -672) in sector 113, floor 56, and every sector round it is 144 at floor -8, a drop of 64 over the 24 P_TryMove allows.
- The oracle is the rest. A monster mid-chase at (488, 256) reads zero differing pixels against Chocolate Doom at 16, 20 and 24 tics, and the demon head on reads zero at 9 and 12.

### Two faults found on the way

- **A thing spawns with movedir DI_EAST, not DI_NODIR.** `P_SpawnMobj` clears the whole mobj and DI_EAST is the zero of `dirtype_t`, so a thing's first `A_Chase` snaps its facing to the eight directions and turns it, and `P_NewChaseDir` starts with a turnaround of DI_WEST. With DI_NODIR the first chase tic leaves the facing alone and the oracle reads 263 differing pixels where it should read none.
- **The sprite loader followed a type's spawn chain alone.** No run or attack frame was ever copied, so a monster that left its idle rows drew nothing at all, which is most of what ticket 15's ten pinned frames were measuring. `Gfx.sprite.woken` follows the chase, melee and missile rows beside the death rows the damage pass marks.

### Integrated verification

All ten inherited moving frames and all 20 rest poses now match Chocolate Doom 3.1.1 with zero differing pixels. The two blue-key impact frames and the demon's bite at tic 20 are included. Reports from 2026-09-21 are in `/tmp/m6-routes/{combat-qa,last-moving,rest-oracles}.json` and `/tmp/m6-palette/oracles.json`.

The four short chase cases were checked against the actual Chocolate Doom engine through GDB. Every tic agrees on monster x/y, angle, move direction, remaining state tics, player health and `P_Random` index: head-on 12 tics, room 24, corner 24, ledge 40. The traces and comparison are in `/tmp/m6-chase/`. These values are no longer regression pins.

The manual-door case in `tests/drops.bend` starts one zombieman at 448,2128 in S_POSS_RUN1 with the player as its target across shut door 80. The player sends only idle commands. Chocolate Doom opens the door on tic 7; its ceiling is -126 on tic 8 and -4 by tic 100. At tic 100 the monster is at fixed-point coordinates 29211840,136463168 with zero momentum and random index 73. The Bend replay prints those same values. The independently captured trace is `/tmp/m6-chase/door/trace.log`.

The complete Freedoom route now reaches the exit at tic 2060, alive with 25 health and 82 armour, and its final intermission frame matches Chocolate Doom. `tests/route.bend` retains the full demo; ticket 25 records the route acceptance.

### Laws

- `thing_move_is_checked` is `move_is_checked`'s twin: a thing's move is taken only where its box passed the check with mask 3, for all bodies, things, levels and places. `walks_taken` is the lemma that `Sim.walks` ands the shared rules with the ledge.
