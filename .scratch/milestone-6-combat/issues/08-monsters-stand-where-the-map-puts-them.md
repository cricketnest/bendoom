# 08: Monsters stand where the map puts them

**What to build:** The zombiemen, shotgun guys, imps and demons of the two E1M1s spawn on Hurt Me Plenty and stand in their idle frames, solid and shootable, facing as their records say, drawn with their rotated and mirrored sprites. They do nothing else yet. The oracle turns monsters on for good.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] The thing tables gain the four types' definitions and idle rows; the counts per type match a nushell census of both WADs (Freedoom: 4 zombiemen, 10 shotgun guys, 10 imps, 5 demons; shareware: 4 zombiemen, 2 imps)
- [x] Spawning draws from the random table where `P_SpawnMapThing` does, so the index after spawn matches a nushell replay with monsters on
- [x] The ambush flag is kept from the record's options
- [x] Monsters stop the player and movers as solid shootable things do
- [x] Render cases show a monster from the front, the side and behind and a mirrored rotation, at zero differing pixels, from places where no monster can see the player
- [x] The oracle's demo header turns monsters on; every rest position stays at zero or moves to a place the ticket justifies
- [x] Oracle cases in later tickets hold only while no unported behaviour happens in them, and each ticket says which of its cases those are

## Comments

Every expected value came from outside the Bend code: the WADs read in nushell with `tools/wad.nu`, and milestone 5's replay of `P_SpawnMapThing` extended to spawn monsters too (info.c's states and mobjinfo, p_mobj.h's flags and m_random.c's table parsed from Chocolate Doom 3.1.1's source, a scratch script as before).

The census on Hurt Me Plenty, the records whose options set bit 2 and clear bit 16:

| type | Freedoom records | on HMP | shareware records | on HMP |
| --- | --- | --- | --- | --- |
| 3004 zombieman | 12 | 4 | 9 | 4 |
| 9 shotgun guy | 13 | 10 | 16 | 0 |
| 3001 imp | 18 | 10 | 4 | 2 |
| 3002 demon | 9 | 5 | 0 | 0 |
| 58 spectre | 1 | 0 | 0 | 0 |

So 29 monsters spawn in Freedoom and 6 in the shareware map, and the spectre stays out, as the milestone's spec says. Thirteen of Freedoom's 29 and six of the shareware's are deaf (options bit 8).

What was built:

- `src/things.bend` gains eight state rows, `S_POSS_STND` to `S_SARG_STND2`, each 10 tics and each leading to the other, and four definitions: 3004, 9 and 3001 at radius 20, height 56, and 3002 at radius 30, all with `MF_SOLID|MF_SHOOTABLE|MF_COUNTKILL`, 4194310. Nothing else changed in the spawn: monsters spawned because they now have definitions.
- The idle rows' action is `Null{}`, not a named `Look{}`. Vanilla's `A_Look` belongs there and the table's comment says so, but the only dispatch over `Thing.Action` today is the weapon sprite's, where a `Look{}` case could only be a branch that never runs. Ticket 15 adds the mobj dispatch and turns those eight `Null{}`s into `Look{}` in the same diff.
- `Thing.ambush` is `P_SpawnMapThing`'s `MF_AMBUSH`: a map thing's id is its record's index, so the flag is read back from the record's options rather than stored on the thing, and a thing spawned in play, whose id is past the records, has none. That keeps this ticket out of ticket 03's `Thing` record.
- The oracle's demo header carries 0 in the no-monsters byte (`src/demo.bend`, `tools/demo.nu`, `tests/demo.bend`), so Chocolate Doom now spawns the map's monsters in every oracle case, film and sound capture.

The random index after spawn, from the replay, and what Bendoom prints:

- Freedoom: 209 things, 312 draws (254 as before plus two for each of the 29 monsters, one for `lastlook` and one for the idle state's tics), so the index is 56; the three light flashes take it to 59. The sim test prints 59.
- Shareware: 91 things, 143 draws, one flash, so 144. Running the sim test binary with `BENDOOM_IWAD` set to `doom1.wad` prints 91 things and 144.

Every spawn tic in the tests comes from that replay: the sim test's six old records and four new monster lines, the state rows of ids 2, 6, 87, 24, 121, 144 and 172, and the route test's restored records all match it. The blink lights come from a nushell replay of `T_LightFlash` and the in-sync `T_StrobeFlash` over the random table from index 56; run from 254 the same script reproduces milestone 5's pinned lines, which is what tells me the replay is right. The sim test's light tics moved (0, 1, 8, 9, 15, 35, 36, 41, 65, 70, 71, 76, 77, 80, 81, 82, 83, 91, 135, 142, 144) so that the lines still land on the blinks' turns at the new index.

A standing monster is a wall, and that is what most of this ticket's work was:

- The sim test's first-door cases walk from 872, 384 instead of 832, 384: the deaf zombieman of record 176 stands at 816, 448, and a player at x 832 cannot pass it. The same zombieman rules out a comparable oracle case at that door, so the render test's half-open door moved to the north rooms' middle door, line 480, approached from 448, 1968, where no monster sees the player even with the door open.
- The render test's railed pit moved from 488, 256 to 488, 320. The zombieman of record 177, at 752, 336, sees the old spot down the pit; the new one is 64 north of it and out of its sight, and shows the same view.
- `tests/route.bend`'s route was rebuilt leg by leg with `tools/walk.bend`. Nine legs changed. The new route passes east of the zombieman behind the south door, threads the 46-unit gap the south-east room's monsters leave (east of the imp at 2320, -160 and west of the demon at 2448, -224) on the way to the blue key and back, crosses the pit along its south side rather than its north-west corner, goes up the hall west of its two imps, and reaches the exit switch by walking round the north of the shotgun guy standing at it and using at 202.5 degrees, which reaches the switch through the alcove past him. `tests/game.bend`'s walk to the same switch changed the same way. The route still takes the blue key and both blue doors, and it ends the level at tic 1865 with 197 of the 209 things left.
- The pit's north-west corner is now sealed: between the zombieman at 752, 336 and the ledge the passable band is under two units wide, so no scripted walk gets from the pit's west end to the first door that way. The route goes along the pit's south side instead. When the monsters chase (tickets 14 to 16) both ways open again.

The oracle, Freedoom, every case of `tests/render.bend` (20 idle tics unless a script is given), one run each:

| case | place | script | differing |
| --- | --- | --- | --- |
| start | -416 256 0 | | 0 |
| lit | 736 464 135 | | 0 |
| dark | -416 256 90 | | 0 |
| step | 137 256 45 | | 0 |
| grate | -416 256 180 | | 0 |
| water | 3 256 0 | | 0 |
| sky | -640 256 90 | | 0 |
| pit (moved) | 488 320 0 | | 0 |
| sergeant | 1144 259 315 | | 0 |
| once | 256 1088 0 | | 0 |
| overlap | 2752 960 0 | | 0 |
| walls | 704 256 0 | | 0 |
| ledge | 256 128 90 | | 0 |
| yard | -640 256 0 | | 0 |
| bars | 1024 200 0 | | 0 |
| demon head on | 48 1616 180 | `6,0,0,0,0` | 0 |
| shotgun guy from behind | 896 2048 270 | | 0 |
| shotgun guy from the side | 987 1947 225 | | 0 |
| demon mirrored | 2448 2112 0 | | 0 |
| stride | -416 256 0 | `34,50,0,0,0` | 0 |
| door half open (moved) | 448 1968 90 | `20,0,0,0,0 20,25,0,0,0 1,0,0,0,1 20,0,0,0,0` | 0 |
| switch pressed | 2064 -260 90 | `20,0,0,0,0 10,25,0,0,0 1,0,0,0,1 27,0,0,0,0` | 0 |
| bonus before | 2590 780 90 | `20,0,0,0,0 18,25,0,0,0` | 0 |
| bonus after | 2590 780 90 | `20,0,0,0,0 19,25,0,0,0` | 0 |
| stimpack and medikit before | 0 400 90 | | 0 |
| stimpack and medikit refused | 0 400 90 | `20,0,0,0,0 16,25,0,0,0 24,-25,0,0,0` | 0 |
| rocket before | 714 -1011 90 | `20,0,0,0,0 1,0,0,16,0 11,0,-24,0,0` | 0 |
| rocket after | 714 -1011 90 | `20,0,0,0,0 1,0,0,16,0 12,0,-24,0,0` | 0 |
| pistol rising 8 | -416 256 0 | `8,0,0,0,0` | 0 |
| bob low 48 | -416 256 0 | `20,0,0,0,0 28,25,0,0,0` | 0 |
| bob right 64 | -416 256 0 | `20,0,0,0,0 44,25,0,0,0` | 0 |

The frames a monster's waking spoils, which are regression pins until ticket 15 gives Bendoom `A_Look` and tickets 14 to 16 the chase, with the count each reports today:

| case | place | script | differing |
| --- | --- | --- | --- |
| air | -416 256 0 | `56,50,0,0,0` | 148 |
| landed | -416 256 0 | `66,50,0,0,0` | 773 |
| blink dark | 640 712 180 | `66,0,0,0,0` | 41680 |
| key 22 | 2380 600 180 | `22,0,0,0,0` | 43 |
| key bright 23 | 2380 600 180 | `23,0,0,0,0` | 43 |
| key before | 2246 592 180 | `20,0,0,0,0 1,0,0,-16,0 12,0,-24,0,0` | 18 |
| key after | 2246 592 180 | `20,0,0,0,0 1,0,0,-16,0 13,0,-24,0,0` | 67 |
| green armour before | 1631 1008 90 | `20,0,0,0,0 11,25,0,0,0` | 541 |
| green armour after | 1631 1008 90 | `20,0,0,0,0 12,25,0,0,0` | 607 |
| chainsaw after | 3158 2176 180 | `20,0,0,0,0 1,0,0,-16,0 13,0,-24,0,0` | 575 |

The blink frame is the loss that hurts: sector 33's alcove is only visible from the corridor its four imps watch, so the one frame that checked a blinking wall against vanilla cannot be compared until the monsters wake. The lights themselves are still checked, against the replay, in the sim test.

Which case can be compared was worked out before each run by a scratch nushell replay of `P_LookForPlayers` and `P_CheckSight` (the field of view, `MELEERANGE`, the REJECT lump and the openings along the ray) over the monsters the spawn replay places. Every place it called unseen came back 0 from the oracle, and the ten above are places it called seen. The new monster cases were found by sampling rings around each monster and keeping the places the tool called unseen: the demon's head-on case has no such place, since a monster that faces you sees you, so that case runs 6 tics, inside the 7 its spawn drew, before its first `A_Look`.

The four monster frames show their monster. Rendering each place from a copy of the WAD whose record is moved to the start changes 3758 pixels (the demon head on, rotation 1), 375 (the shotgun guy from behind, rotation 5), 736 (the same one from its side, rotation 4) and 1706 (the demon at rotation 6, which `SARGA4A6` draws mirrored).

Laws: `monsters_block` says every type the tally counts as a kill is solid and shootable, so a monster stops the player as `clear_pins_things`'s solids do; `states_exist` says every definition's spawn state and every row's next state is a row of the table, which is what keeps the eight new rows honest. `radius_within` and `solid_stays` are folds over `H.Thing.defs()`, so they cover the four new types with no change.

What was deleted: the no-monsters byte from the demo header and every comment that spoke of it (`src/demo.bend`, `tools/demo.nu`, `tools/oracle.nu`), `src/things.bend`'s "less the monsters", the sim test's "no monsters" and its note that record 3 is a monster that does not spawn, and the render test's claim that the oracle finds no pixel off vanilla's in every frame but three.

Trade-offs:

- **The route lost the tech column that used to hold it.** The old leg walked into record 59 and strafed past; the new route passes the column at a distance. The solid-thing check it exercised is still the sim test's `solids`, which walks the player into that same column and into a corpse.
- **The route is no longer compared with Chocolate Doom leg by leg.** Milestone 5's ticket 11 did that; with monsters awake in vanilla no long route can match, so the route test is a pin for what the player reaches and what it carries until the monsters chase.
- **`tools/listen.nu`'s sound capture now hears monsters.** It shares `tools/demo.nu`, so a script whose place a monster sees will have that monster's sight sound in the capture; its music capture passes `-nomonsters` on the command line and is unchanged.
