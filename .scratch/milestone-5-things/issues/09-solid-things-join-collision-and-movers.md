# 09: Solid things join collision and movers

**What to build:** Solid map things become real obstacles. The player cannot overlap barrels or solid scenery, but can cross corpses, gore and non-solid decorations. Moving floors carry things standing on them and moving ceilings re-clip the active population through the same height rules as the player. Damage and explosions remain absent.

**Blocked by:** 06 (The blue key opens its door)

**Status:** resolved

- [x] Position checking examines nearby things through the blockmap before it examines lines
- [x] Two radii decide a solid collision as vanilla does; vanilla tests no height for a thing that is not a missile
- [x] Solid decorations and barrels stop the move; non-solid scenery and pickups do not
- [x] A thing standing on a moving floor follows it and retains its stable identity and state
- [x] A moving ceiling updates thing floor and ceiling bounds and reports a blocked move when an undamageable solid thing no longer fits
- [x] Crushing damage and barrel explosions are not introduced
- [x] The player's completed tic is free of every active solid thing, stated and filled as a law
- [x] Sim tests cover a blocked decoration, a passable corpse, a carried thing and a blocked mover on both lanes
- [x] Existing line collision, re-clip and mover timelines stay green


## Comments

Every expected value came from outside the Bend code: linuxdoom-1.10's and Chocolate Doom's p_map.c, p_maputl.c, p_mobj.c and p_floor.c, the WAD read in nushell, hand arithmetic, and Chocolate Doom on the oracle's scripts.

The ticket first asked for intersecting vertical ranges. Vanilla has none: PIT_CheckThing tests heights only when the mover is a missile, so a walking thing is as tall as the map, and the checkbox now says so. The `thing_blocks` law pins it with a lamp raised 100 units that still stops the player. The spec's wording is corrected to match, as is its mover rule: only a shootable thing that no longer fits stops a mover, and PIT_ChangeSector passes over any other.

What was built:

- **Blocklinks.** The level's THINGS record also holds Doom's blocklinks for the things spawned: a head per blockmap cell and four words a thing (next, x, y, type), linked in spawn order, so each cell lists the last spawned first, as P_SetThingPosition does. A thing never moves in this milestone, so no tic writes them and they sit with the geometry the wall law already keeps. Their x, y and type are a copy of the thing's.
- **The population** is a tree by record id (`H.Things`), so a pickup, a carry or a lookup touches only its own thing. `H.Things.list` gives the renderer and the tests the things in id order, as before. The population also holds the player's link rank: its start record until its first successful move, then first in its cell, as P_TryMove's unlink and relink put it.
- **The position check** is P_CheckPosition in its order. It walks the things linked in the cells of the box widened by MAXRADIUS: columns west to east, rows south to north, each cell's list in order, each thing once. A special thing the player overlaps is offered to the inventory. The first solid thing that overlaps ends the check, before any line, at the floor and ceiling of the sector under the point. Otherwise the lines follow, and PIT_CheckLine's early stop now holds: the first line that stops the box ends the narrowing where it is. A pickup taken before a later thing or line refuses the move stays taken. The ticket-06 scan of the whole population is gone. Line checks take a radius and a mask: the player's is 16 and blocking lines; a thing's is its own radius, and lines blocking monsters stop it as well.
- **Movers** are P_ChangeSector. Every mobj linked in the cells of the sector's block box is clipped again in the blockmap's order: each thing, and the player at its link. P_ThingHeightClip's rule (`Sim.clip`, `Sim.fits`) is shared by the player and the things. A thing's own check is stopped by any solid thing its box overlaps, the player's included. A thing that no longer fits stops the mover only when it is shootable; T_MovePlane's undo then clips everything again. A ceiling rising short of its destination ignores what no longer fits, as T_MovePlane does. No E1M1 mover crushes, map things are neither dead nor dropped, and nothing is damaged, gibbed or removed. `Level.blocked`, which re-clipped only the player, is gone.

The laws, all filled; `bend PROOF.bend` prints "All terms check.":

- `replay_keeps_clear`, the freedom law: replaying any script from a free state leaves the player's box clear of every solid thing linked near it. `Free` is P_CheckPosition's verdict, now lines and things, so the wall law's proof carries both. Its fold lemmas were reworked for the early stop, and the freedom law follows from it.
- `clear_pins_things` reads the verdict on each thing: any thing listed in the cells around the player, whichever position it holds, does not stop the box. `radius_within` shows no type is wider than the 32 the check widens by, so a thing linked further away cannot reach the box. `blocker_geometry` shows the numbers: a lamp stops the box at 32 minus 1/65536 and not at 32, never its own box, a corpse never, a barrel at 26. The universal statements stop at the cells, as `free_pins_lines` does for lines: U32 arithmetic does not compute in the checker (docs/bend.md).
- Closed laws, by hand from vanilla's constants. `thing_blocks`: 79.25 after tic 2, held there on tic 3; the raised lamp stops it too; over a corpse it reaches 85.82. `floor_carries_things`: a barrel follows a floor down 4 a tic, a hung leg stays at 60. `barrel_stops_door`: 42 after tic 13, the 14th undone, 44 after the 15th. `lamp_under_door`: a solid, unshootable lamp does not stop the door, which shuts on tic 34. `door_opens_over_barrel`: 2 and 4 up over a barrel that does not fit. `link_order` places the player's link in its cell. `line_geometry` gained box radii and the monster-blocking flag.
- A mutated expected value fails the check in `thing_blocks` and in `barrel_stops_door`, so the laws compute.

The sim cases, on Freedoom, in tests/sim.bend, both lanes:

- **Blocked decoration.** Walking south from -192, 1712 at the tech column, record 59: tic 37 leaves the player 35.78 north of it. Tic 38's step of 6.92 would bring it to 28.86, under the 32 of the two radii, so the player stays through tic 48.
- **Passable corpse.** Walking south from 128, 432 over the dead former human, record 171: the positions equal the free walk (432 less the column walk's distance, 399.121368 at tic 30), across the corpse's box.
- **Carried thing.** A tech column on lift 98 at 96, 216, as record 3. Its height, floor and ceiling follow the lift from 12 down to -124 and back, with id, type, state and tics kept.
- **Blocked mover.** A barrel in door 10 at 800, 528, as record 35. The shut door opens over it. Closing, it is undone at -86 on tic 295, 2 short of leaving 40 of the barrel's 42, and goes back up: -84 on tic 296, -74 on tic 301.
- Records 3 and 35 are monsters, which neither game spawns. For the oracle, a scratch copy of the IWAD rewrites them in place as these things, passed with `--wad`. The test adds the same things under the same ids.

The oracle (every thing kept; the control is the ticket 06 build's frame dump on the same script):

| case | place | script | differing | control |
| --- | --- | --- | --- | --- |
| column, tic 37 | -192 1712 270 | `20,0,0,0,0 17,25,0,0,0` | 0 | |
| column, tic 38 | -192 1712 270 | `20,0,0,0,0 18,25,0,0,0` | 58 | |
| column, tic 48 | -192 1712 270 | `20,0,0,0,0 28,25,0,0,0` | 136 | 42107 |
| corpse, tic 30 | 128 432 270 | `20,0,0,0,0 10,25,0,0,0` | 6 | |
| corpse, tic 38 | 128 432 270 | `20,0,0,0,0 18,25,0,0,0` | 0 | |
| carried, tic 12 | 240 256 180, --wad | `10,25,0,0,0 1,0,0,0,1 1,0,0,0,0 6,0,0,0,0` | 0 | 0 |
| carried, tic 44 | 240 256 180, --wad | `… 32,0,0,0,0` | 0 | 3606 |
| carried, tic 184 | 240 256 180, --wad | `… 32,0,0,0,0 1,0,0,0,0 105,0,0,0,0 34,0,0,0,0` | 0 | 0 |
| door, tics 294, 295, 296 | 832 384 90, --wad | `40,25,0,0,0 1,0,0,0,1 61,0,0,0,0 192,0,0,0,0` and 1 or 2 idle | 110 each | |
| door, tic 301 | 832 384 90, --wad | `… 7,0,0,0,0` | 38 | 48207 |

Each nonzero count is a small patch outside the collision: at column tics 38 and 48, armor bonus 126, 196 units ahead (columns 51 to 59, rows 101 to 111), changing frame in vanilla on a tic when neither player moves; for the door, the barrel's lights and distant items, all below the door's edge (rows 84 to 153); for the corpse, 6 pixels at columns 310 to 313. This base has no thing animation or full-bright frames; ticket 05 brings them. A collision or mover difference shifts the whole view: the controls differ by thousands. A floor lamp tried first as the carried thing differed in all 1294 of its pixels (columns 90 to 114, rows 79 to 146) because vanilla draws it full-bright, so the tech column replaced it.

**The route.** Freedoom's route test ran south into the tech column at -192, 1600. Chocolate Doom plays the unchanged script to the same frames: 0 differing pixels at the end of the south run and at the end of the script, where the ticket 06 build differs in 47586 after the south run. So the old commands no longer reach the exit switch in vanilla either. Its pins are updated to vanilla's outcome, and its header says so; routing around the column is ticket 11's. Every other existing expected value is unchanged.

**Cost**, native, dev machine: a level start went from 50 to about 88 ms, mostly the spawn's sector lookups, which linking now forces at start where the old build left them lazy; linking itself is 3 ms. A tic of walking went from about 0.22 to about 0.39 ms, well inside a frame. The sim test runs in 3.8 s (1.5 s before, with the new cases added), route 630 ms (343), render 3.3 s (1.9 s).

Trade-offs and limits:

- **Static links.** A thing never moves, so its links are written once at spawn. Milestone 6's monsters will need them written as they move.
- **No P_ZMovement for things.** A thing not on its floor is only clipped under its ceiling. Vanilla's P_ZMovement would also lift it back to a floor above it. In either E1M1 no mover reaches such a thing: the only boxes that cross another sector's line near a mover lead to sectors that do not move, and the hung leg by door 80 crosses none.
- **Crushers** would damage in vanilla; E1M1 has none, so `crush` is not represented.

Checks: every test on both lanes; `bend PROOF.bend`; `nix flake check`; `git diff --check`.
