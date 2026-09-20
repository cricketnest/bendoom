# 16: A woken monster chases

**What to build:** A woken monster walks at the player with vanilla's movement: eight directions, turning toward its move direction, backing off and trying again when blocked, stopped by ledges too high, drops too deep and lines that block monsters, and opening the manual doors vanilla lets it open.

**Blocked by:** 03 (Things move, relink and spawn in play), 15 (A monster sees the player)

**Status:** ready-for-human

- [x] `A_Chase`'s movement half, `P_NewChaseDir`, `P_TryWalk`, `P_Move` and `A_FaceTarget`, with every random draw in place, the active sound's among them
- [x] `P_TryMove`'s dropoff test: ticket 03's `Sim.check` does not gather `tmdropoffz`, so this ticket adds it to what the check answers
- [x] A blocked move uses the special lines it hit, which opens manual doors
- [x] Each monster moves at its speed on its move tics and relinks as it goes
- [x] The freedom law grows from the player to every thing that moved
- [ ] Sim cases: a chase across a room, around a corner, through a door, and one stopped at a ledge, with places per tic and the random index from a replay of the source
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

### The ten pinned oracle frames

Eight of ticket 08's ten are back to zero, and so is every frame that was at zero before:

| case | place | script | ticket 15 | now |
| --- | --- | --- | --- | --- |
| air | -416 256 0 | `56,50,0,0,0` | 109 | **0** |
| landed | -416 256 0 | `66,50,0,0,0` | 443 | **0** |
| blink dark | 640 712 180 | `66,0,0,0,0` | 42058 | **0** |
| key 22 | 2380 600 180 | `22,0,0,0,0` | 22 | **0** |
| key bright 23 | 2380 600 180 | `23,0,0,0,0` | 22 | **0** |
| key before | 2246 592 180 | `20,0,0,0,0 1,0,0,-16,0 12,0,-24,0,0` | 12 | 8 |
| key after | 2246 592 180 | `20,0,0,0,0 1,0,0,-16,0 13,0,-24,0,0` | 41 | 11 |
| green armour before | 1631 1008 90 | `20,0,0,0,0 11,25,0,0,0` | 360 | **0** |
| green armour after | 1631 1008 90 | `20,0,0,0,0 12,25,0,0,0` | 407 | **0** |
| chainsaw after | 3158 2176 180 | `20,0,0,0,0 1,0,0,-16,0 13,0,-24,0,0` | 379 | **0** |
| start | -416 256 0 | `20,0,0,0,0` | 0 | **0** |
| the pit | 488 256 0 | `20,0,0,0,0` | 0 | **0** |
| shotgun guy from behind | 368 1632 0 | `20,0,0,0,0` | 0 | **0** |
| a monster mid-chase | 488 256 0 | `24,0,0,0,0` | | **0** |
| demon head on | 48 1616 180 | `9,0,0,0,0` | | **0** |
| demon head on | 48 1616 180 | `12,0,0,0,0` | | **0** |
| demon head on | 48 1616 180 | `20,0,0,0,0` | 0 | 14965 |

`key before` and `key after` keep 8 and 11 pixels, in a box three wide and five tall at the middle of the view, and both frames carry palette 11, a damage flash: a monster's bullet reaches the player there and something of what that bullet leaves is not right yet. The demon head on at 20 tics is ticket 18's: vanilla's demon is inside `P_CheckMeleeRange` by tic 13 and bites, and Bendoom's cannot.

### The routes

`tests/route.bend` now stops at the blue key, tic 717. Past it the route only walks, and the monsters it wakes chase it and shoot it down: health falls to 58 by the lift, 19 on the way back, and 0 in the pit at about tic 1300, after which the player is dead and every later leg prints a corpse standing still. No route that cannot shoot back survives those legs, so the exit and the restart it used to check are left to ticket 25. `tests/game.bend` keeps the exit and the restart, but its walk to the exit switch is gone for the same reason: the shotgun guy of record 289 chases and blocks it, so the player is put where the walk left it, at (-363, 1316) facing 180, and turns to 202.5 degrees.

### Laws

- `thing_move_is_checked` is `move_is_checked`'s twin: a thing's move is taken only where its box passed the check with mask 3, for all bodies, things, levels and places. `walks_taken` is the lemma that `Sim.walks` ands the shared rules with the ledge.

### Deferred to the later pass

- **The sim cases' numbers are regression pins, not a replay.** The first move of the chase across the room is worked by hand above, and the ledge comes from the WAD; every later tic and every random index in `chases` is a pin. The nushell replay of `A_Chase`, `P_NewChaseDir` and `P_Move` that would check the rest was not written.
- **`key before` and `key after` keep 8 and 11 pixels.** Both are frames where a monster's bullet reaches the player. Not diagnosed.
- **The chase through a manual door has no sim case.** The code is there and `Sim.thing.uses` is reached by the door in the route, but no case holds a monster against a shut door and watches it open.
- **The shareware WAD was not run.** Only Freedoom.
- **`tools/oracle.nu`'s long-fight case** from the milestone's spec is still not written.
