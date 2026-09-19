# 10: The populated maps match Chocolate Doom

**What to build:** The oracle compares Bendoom with the real non-monster population of each E1M1. It replaces only player 1's start, removes monsters, keeps supported decorations and items, and runs both games on Hurt Me Plenty. Static sprites, animation, occlusion, masked-wall depth, pickup removal and the blue-key door are each compared at exact tics.

**Blocked by:** 04 (Sprites and masked walls share the depth pass), 05 (Animated and full-bright things keep vanilla time), 07 (Health, armour and powers are pickups), 08 (Ammo, backpacks and world weapons are pickups), 09 (Solid things join collision and movers)

**Status:** resolved

- [x] The oracle no longer replaces THINGS with one record; it preserves supported things, removes monsters and rewrites player 1's start in place
- [x] Chocolate Doom runs with no monsters and Hurt Me Plenty options matching Bendoom
- [x] Existing status-bar, pause and first-person-weapon masks remain; no world-sprite pixel is masked
- [x] Static decorations, overlap, wall and ledge clips, and both masked-wall depth orders each report zero differing pixels
- [x] Animated and full-bright frames at chosen exact tics report zero differing pixels
- [x] A supported pickup is present one tic before contact and absent one tic after in both games
- [x] The blue key door refuses before collection and opens after it at matching tics
- [x] Existing milestone 3 and 4 oracle positions are rerun with things present, with every count recorded
- [x] Any nonzero count is fixed or tied to a stated out-of-scope first-person weapon difference, never hidden by a new mask
- [x] Both WADs' results are recorded; the unfree WAD remains outside the flake

## Comments

Built on the merge of ticket 09 into m5-pickups (de65316), where every case tickets 01 to 09 reported runs at 0; its message has the merge's reruns.

**The oracle, verified rather than rebuilt.** Ticket 02 made `tools/oracle.nu` keep every THINGS record and write player 1's start over its own record, on every skill. Read on this branch: the demo header is `6d 02 01 01 00 00 00 01 00 01 00 00 00`, version 109, skill 2 (Hurt Me Plenty), E1M1, no deathmatch, respawn or fast, no monsters (the byte `-nomonsters` sets), console player 0, player 1 alone. The comparison covers the 168 view rows and leaves out only the pause graphic and the pistol, widened by the bob's reach when the script moves; no mask covers a world sprite, and none was added.

What changed in the oracle: `--things "record,type,x,y ..."` rewrites more records in place, each on every skill and facing 0, and the frame dump now reads the same scratch copy of the IWAD as Chocolate Doom. The start's rewrite is the same `rewrite`, so `start-iwad` is gone. Ticket 09 compared its patched cases through an unrecorded `--wad` copy; that copy is now one flag, and the sim test patches the same bytes (`tests/sim.bend`'s `patched`: records 3, 35 and 82).

**The blue key door.** Record 87, the map's blue key, stands behind the fence at 2192, 576; door 71 closes the far end of the long hall at 768 to 896, 1480, about 1600 units and several doors away. Ticket 06 left the walk between them to ticket 11's route, and ticket 06's door heights were hand values handed a constructed inventory. So the case follows ticket 09's precedent for sim cases vanilla can play: monster record 82, an imp neither game spawns, is rewritten as a second blue card at 824, 1352, in the hall south of the door, and one replay refuses, takes and opens:

- From 880, 1440 facing north, 20 idle tics and a use on tic 21. The use line crosses the door's face at x 880, inside its 768 to 896, and the door stays shut.
- 20 idle tics, a turn to 247.5, and a walk that takes the card on tic 56: the player is 34.43 east and 35.87 north of it, inside the reach of 36 (tic 55 leaves it 36.81 east). Ten idle tics more than the first try put that tic in the bob's trough, the eye 36 over the floor, so the card stays in view at 49.7 units; on the hall's flat floor a pickup nearer than about 50 is below the view.
- 20 idle tics, a turn north, 19 tics forward, and a use on tic 97 from 1423.47, 56.53 short of the door's line. The door is -126 after that tic, -116 at 102 and -86 at 117 (VDOORSPEED 2), and it stops at -4 on tic 158, 4 under the ceilings of 0 beside it.

`tests/sim.bend`'s `locked` prints those tics on both lanes. The frames at 21, 41, 55, 56, 97, 102, 117 and 158 report 0 against Chocolate Doom (table below). Each compared frame shows what it is for, measured against our own frames from throwaway variants of the patched WAD and one throwaway build, none committed:

- Line 421 made special 1, a door with no lock: 27,865 pixels of the tic 21 frame differ and 33,538 of the tic 41 frame. So a door that had opened would fail both.
- Record 82 moved out of view, same type and random draws: 910 unmasked pixels of the tic 55 frame differ. So the card is present in both games.
- A build whose grant never takes the card: 920 unmasked pixels of the tic 56 frame differ. So the card is gone in both games.

The sim test's two walks from ticket 06 that handed door 71 the start's inventory and the key's are replaced by this one; the walk holding the blue skull alone stays, since vanilla's demo cannot give a skull.

**Ticket 09's triage.** `tests/sim.bend` walks every blockmap cell of each E1M1 as loaded, `L.Level.load` and `State.start`. For each link it checks the thing is alive, at the link's x and y, of its type, with its centre in that cell; for each thing, that it is in the list of its centre's cell. Freedoom (in the flake): 180 links for 180 things, 79 solid of 79, none wrong, none unlinked. Shareware (local): 85 of 85, 18 solid of 18, none wrong, none unlinked. The solid counts are the solid types in ticket 02's nushell inventory (Freedoom 1 + 12 + 18 + 4 + 15 + 7 + 22, shareware 2 + 2 + 8 + 6). The new closed law `solid_stays` says no type is both solid and special, so no pickup removes a solid thing; a false expected value fails the proof at that law. Ticket 09 is resolved, and its comments say what is proved, what rests on this check, and what stays an argument.

**The route** stops at the tech column in both games: 0 differing pixels after the run south (tic 487) and at the end of the script (tic 590). Ticket 11 routes around it.

**The shareware WAD** runs outside the flake with `--wad` set to `doom1.wad`. Its cases are the five earlier tickets placed on it: the start, the pedestal, the nukage, and the blue armour before and after. These Freedoom cases have no shareware equivalent, because each is a place in Freedoom's map: the sprite rules' scenes (once, overlap, walls, ledge, yard, bars, grate), the key frames, the other pickups, the solid things' scenes, the route, and the blue key door. The shareware E1M1 has no blue key or skull and no blue-locked line. No scene was invented for it. The links check covers it through the sim test's binary.

**The oracle table.** 64 cases, every one 0; each script is the whole demo. "patched" is `--things "3,48,96,216 35,2035,800,528 82,5,824,1352"`: the tech column on the first lift, the barrel in the first door and the blue card, as `tests/sim.bend`'s patched map has them. Ticket 09's carried and barrel door cases are rerun on that map (0 on ticket 09's two-record copy too; see the merge). Each tic in a name is the script's length. No count is tied to the first-person weapon, since none is nonzero.

| case | WAD | place | script | things | differing |
| --- | --- | --- | --- | --- | --- |
| start | Freedoom | -416 256 0 | `20,0,0,0,0` |  | 0 |
| lit | Freedoom | 736 464 135 | `20,0,0,0,0` |  | 0 |
| dark | Freedoom | -416 256 90 | `20,0,0,0,0` |  | 0 |
| step | Freedoom | 137 256 45 | `20,0,0,0,0` |  | 0 |
| grate | Freedoom | -416 256 180 | `20,0,0,0,0` |  | 0 |
| water | Freedoom | 3 256 0 | `20,0,0,0,0` |  | 0 |
| sky | Freedoom | -640 256 90 | `20,0,0,0,0` |  | 0 |
| pit | Freedoom | 488 256 0 | `20,0,0,0,0` |  | 0 |
| sergeant | Freedoom | 1144 259 315 | `20,0,0,0,0` |  | 0 |
| once | Freedoom | 256 1088 0 | `20,0,0,0,0` |  | 0 |
| overlap | Freedoom | 2752 960 0 | `20,0,0,0,0` |  | 0 |
| walls | Freedoom | 704 256 0 | `20,0,0,0,0` |  | 0 |
| ledge | Freedoom | 256 128 90 | `20,0,0,0,0` |  | 0 |
| yard | Freedoom | -640 256 0 | `20,0,0,0,0` |  | 0 |
| bars | Freedoom | 1024 200 0 | `20,0,0,0,0` |  | 0 |
| stride | Freedoom | -416 256 0 | `34,50,0,0,0` |  | 0 |
| air | Freedoom | -416 256 0 | `56,50,0,0,0` |  | 0 |
| landed | Freedoom | -416 256 0 | `66,50,0,0,0` |  | 0 |
| door | Freedoom | 832 384 90 | `20,0,0,0,0 20,25,0,0,0 1,0,0,0,1 20,0,0,0,0` |  | 0 |
| switch | Freedoom | 2064 -260 90 | `20,0,0,0,0 10,25,0,0,0 1,0,0,0,1 27,0,0,0,0` |  | 0 |
| blink | Freedoom | 640 712 180 | `66,0,0,0,0` |  | 0 |
| key dim, tic 22 | Freedoom | 2380 600 180 | `22,0,0,0,0` |  | 0 |
| key bright, tic 23 | Freedoom | 2380 600 180 | `23,0,0,0,0` |  | 0 |
| armour and bonuses, tic 20 | Freedoom | 1600 1000 90 | `20,0,0,0,0` |  | 0 |
| armour and bonuses, tic 27 | Freedoom | 1600 1000 90 | `27,0,0,0,0` |  | 0 |
| key before, tic 33 | Freedoom | 2246 592 180 | `20,0,0,0,0 1,0,0,-16,0 12,0,-24,0,0` |  | 0 |
| key after, tic 34 | Freedoom | 2246 592 180 | `20,0,0,0,0 1,0,0,-16,0 13,0,-24,0,0` |  | 0 |
| bonus before, tic 38 | Freedoom | 2590 780 90 | `20,0,0,0,0 18,25,0,0,0` |  | 0 |
| bonus after, tic 39 | Freedoom | 2590 780 90 | `20,0,0,0,0 19,25,0,0,0` |  | 0 |
| green armour before, tic 31 | Freedoom | 1631 1008 90 | `20,0,0,0,0 11,25,0,0,0` |  | 0 |
| green armour after, tic 32 | Freedoom | 1631 1008 90 | `20,0,0,0,0 12,25,0,0,0` |  | 0 |
| stimpack and medikit before | Freedoom | 0 400 90 | `20,0,0,0,0` |  | 0 |
| stimpack and medikit refused | Freedoom | 0 400 90 | `20,0,0,0,0 16,25,0,0,0 24,-25,0,0,0` |  | 0 |
| rocket before, tic 32 | Freedoom | 714 -1011 90 | `20,0,0,0,0 1,0,0,16,0 11,0,-24,0,0` |  | 0 |
| rocket after, tic 33 | Freedoom | 714 -1011 90 | `20,0,0,0,0 1,0,0,16,0 12,0,-24,0,0` |  | 0 |
| chainsaw before, tic 33 | Freedoom | 3158 2176 180 | `20,0,0,0,0 1,0,0,-16,0 12,0,-24,0,0` |  | 0 |
| chainsaw after, tic 34 | Freedoom | 3158 2176 180 | `20,0,0,0,0 1,0,0,-16,0 13,0,-24,0,0` |  | 0 |
| column, tic 37 | Freedoom | -192 1712 270 | `20,0,0,0,0 17,25,0,0,0` |  | 0 |
| column, tic 38 | Freedoom | -192 1712 270 | `20,0,0,0,0 18,25,0,0,0` |  | 0 |
| column, tic 48 | Freedoom | -192 1712 270 | `20,0,0,0,0 28,25,0,0,0` |  | 0 |
| corpse, tic 30 | Freedoom | 128 432 270 | `20,0,0,0,0 10,25,0,0,0` |  | 0 |
| corpse, tic 38 | Freedoom | 128 432 270 | `20,0,0,0,0 18,25,0,0,0` |  | 0 |
| blue door refused, tic 21 | Freedoom | 880 1440 90 | `20,0,0,0,0 1,0,0,0,1` | patched | 0 |
| blue door still shut, tic 41 | Freedoom | 880 1440 90 | `20,0,0,0,0 1,0,0,0,1 20,0,0,0,0` | patched | 0 |
| card before, tic 55 | Freedoom | 880 1440 90 | `20,0,0,0,0 1,0,0,0,1 20,0,0,0,0 1,0,0,112,0 13,25,0,0,0` | patched | 0 |
| card taken, tic 56 | Freedoom | 880 1440 90 | `20,0,0,0,0 1,0,0,0,1 20,0,0,0,0 1,0,0,112,0 13,25,0,0,0 1,25,0,0,0` | patched | 0 |
| blue door opening, tic 97 | Freedoom | 880 1440 90 | `20,0,0,0,0 1,0,0,0,1 20,0,0,0,0 1,0,0,112,0 13,25,0,0,0 1,25,0,0,0 20,0,0,0,0 1,0,0,-112,0 19,25,0,0,0 1,0,0,0,1` | patched | 0 |
| blue door opening, tic 102 | Freedoom | 880 1440 90 | `20,0,0,0,0 1,0,0,0,1 20,0,0,0,0 1,0,0,112,0 13,25,0,0,0 1,25,0,0,0 20,0,0,0,0 1,0,0,-112,0 19,25,0,0,0 1,0,0,0,1 5,0,0,0,0` | patched | 0 |
| blue door opening, tic 117 | Freedoom | 880 1440 90 | `20,0,0,0,0 1,0,0,0,1 20,0,0,0,0 1,0,0,112,0 13,25,0,0,0 1,25,0,0,0 20,0,0,0,0 1,0,0,-112,0 19,25,0,0,0 1,0,0,0,1 5,0,0,0,0 15,0,0,0,0` | patched | 0 |
| blue door open, tic 158 | Freedoom | 880 1440 90 | `20,0,0,0,0 1,0,0,0,1 20,0,0,0,0 1,0,0,112,0 13,25,0,0,0 1,25,0,0,0 20,0,0,0,0 1,0,0,-112,0 19,25,0,0,0 1,0,0,0,1 5,0,0,0,0 15,0,0,0,0 41,0,0,0,0` | patched | 0 |
| carried, tic 18 | Freedoom | 240 256 180 | `10,25,0,0,0 1,0,0,0,1 1,0,0,0,0 6,0,0,0,0` | patched | 0 |
| carried, tic 50 | Freedoom | 240 256 180 | `10,25,0,0,0 1,0,0,0,1 1,0,0,0,0 6,0,0,0,0 32,0,0,0,0` | patched | 0 |
| carried, tic 190 | Freedoom | 240 256 180 | `10,25,0,0,0 1,0,0,0,1 1,0,0,0,0 6,0,0,0,0 32,0,0,0,0 1,0,0,0,0 105,0,0,0,0 34,0,0,0,0` | patched | 0 |
| barrel door, tic 294 | Freedoom | 832 384 90 | `40,25,0,0,0 1,0,0,0,1 61,0,0,0,0 192,0,0,0,0` | patched | 0 |
| barrel door, tic 295 | Freedoom | 832 384 90 | `40,25,0,0,0 1,0,0,0,1 61,0,0,0,0 192,0,0,0,0 1,0,0,0,0` | patched | 0 |
| barrel door, tic 296 | Freedoom | 832 384 90 | `40,25,0,0,0 1,0,0,0,1 61,0,0,0,0 192,0,0,0,0 2,0,0,0,0` | patched | 0 |
| barrel door, tic 301 | Freedoom | 832 384 90 | `40,25,0,0,0 1,0,0,0,1 61,0,0,0,0 192,0,0,0,0 7,0,0,0,0` | patched | 0 |
| route at the column, tic 487 | Freedoom | -416 256 0 | tests/route.bend, below |  | 0 |
| route end, tic 590 | Freedoom | -416 256 0 | tests/route.bend, below |  | 0 |
| shareware start | shareware | 1056 -3616 90 | `20,0,0,0,0` |  | 0 |
| shareware pedestal | shareware | -120 -3160 180 | `20,0,0,0,0` |  | 0 |
| shareware nukage | shareware | 1800 -3300 0 | `20,0,0,0,0` |  | 0 |
| shareware blue armour before | shareware | 1791 -3360 90 | `26,0,0,0,0` |  | 0 |
| shareware blue armour after | shareware | 1791 -3360 90 | `20,0,0,0,0 16,25,0,0,0 24,-25,0,0,0` |  | 0 |
The route's script from player 1's start, -416 256 0: `35,50,0,0,0 40,0,0,0,0 1,0,0,14,0 50,50,0,0,0 1,0,0,32,0 10,50,0,0,0 1,0,0,18,0 12,50,0,0,0 10,0,0,0,0 1,0,0,0,1 62,0,0,0,0 20,50,0,0,0 1,0,0,30,0 20,50,0,0,0 1,0,0,34,0 10,25,0,0,0 10,0,0,0,0 1,0,0,0,1 62,0,0,0,0 16,50,0,0,0 1,0,0,-64,0 40,50,0,0,0 1,0,0,64,0 36,50,0,0,0 12,0,0,0,0 1,0,0,64,0 22,50,0,0,0 10,0,0,0,0` to the column (tic 487), then `1,0,0,0,1 36,0,0,0,0 8,50,0,0,0 22,0,0,0,0 1,0,0,-64,0 9,50,0,0,0 20,0,0,0,0 1,0,0,0,1 5,0,0,0,0` to the end (tic 590), `tests/route.bend`'s legs in a demo's units.

Checks:

- Every test on both lanes (`tests/*.bend`, native and bun).
- `bend PROOF.bend` prints "All terms check."
- One false expected value in each of the 32 closed laws of tickets 05 to 09, and in `solid_stays`, fails the proof at that law.
- `nix flake check` passes. `git diff --check` is clean.
- The table above, from `tools/oracle.nu` on this build.
