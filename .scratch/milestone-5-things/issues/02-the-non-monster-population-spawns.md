# 02: The non-monster population spawns

**What to build:** Both E1M1 THINGS lumps become their complete milestone 5 populations. Hurt Me Plenty options decide what spawns. Decorations, corpses, barrels and every world item in scope get vanilla definitions and stable map identities. Monsters, other player starts, deathmatch starts, teleport destinations and multiplayer-only records stay out. Restart rebuilds the same population from the loaded map.

**Blocked by:** 01 (One decoration reaches the frame)

**Status:** resolved

- [x] A nushell inventory of both maps records every DoomEd type and option combination before the Bend tables are written
- [x] Every non-monster type used by either E1M1 has the spawn state, radius, height and flags needed by this milestone
- [x] Hurt Me Plenty and multiplayer filtering matches vanilla's map-thing rules
- [x] Floor and ceiling spawns use the sector heights under the thing
- [x] Active things keep stable THINGS-record identities when another thing is later removed
- [x] Restart reconstructs the original population and resets every thing's state
- [x] Monsters and mode-only starts do not appear as inert sprites
- [x] A boundary test prints counts by kind and selected records for Freedoom; the shareware counts are recorded outside the flake
- [x] Both lanes pass; existing movement and render cases remain green

## Comments

Every expected value came from outside the Bend code. The WADs were read in nushell. `tools/wad.nu` gains `things`, `bsp` and `sector-at`, which is R_PointInSubsector over NODES. A throwaway nushell script parsed Chocolate Doom 3.1.1's `info.c`, `p_mobj.c` and `m_random.c` and replayed P_SpawnMapThing record by record. The same script printed the Bend tables, so no row was typed by hand.

The inventory, as type, then options × records:

- Freedoom, 292 records: 1 7×1; 2 7×1; 3 7×1; 4 7×1; 5 7×1; 8 1×1; 9 6×6 7×1 12×3 14×2 15×1; 10 7×3; 11 7×5 23×3; 12 7×3; 15 6×1 7×3; 17 23×2; 18 7×5; 19 1×1 15×1; 20 1×1 7×1; 21 7×2; 24 7×2; 26 7×1; 43 7×12; 47 7×13 15×5; 48 7×4; 54 7×15; 58 12×1; 60 7×1 15×1; 2001 1×2 23×1 31×1; 2002 23×2; 2003 23×1 31×1; 2004 23×1; 2005 15×1; 2007 1×1 7×2; 2008 7×9 15×5 31×4; 2010 7×1 23×3 31×4; 2011 4×4 6×1 7×1; 2012 1×1 3×2 7×2; 2013 31×1; 2014 7×30; 2015 1×4 7×18; 2018 1×1 7×1; 2019 1×1; 2023 3×1; 2028 7×7; 2035 7×15 15×7; 2046 23×2; 2047 7×1; 2048 7×1 23×3; 2049 1×1 4×1 7×1 23×2; 3001 4×5 6×4 7×3 12×3 14×2 15×1; 3002 7×1 12×4 14×3 15×1; 3004 1×3 4×1 7×1 9×4 14×2 15×1.
- Shareware, 138 records: 1 7×1; 2 7×1; 3 7×1; 4 7×1; 9 4×1 12×15; 10 7×2; 11 7×5; 12 7×2; 15 7×4; 24 7×7; 35 7×2; 48 7×2; 2001 7×1; 2002 23×1; 2003 23×1; 2007 15×2; 2008 7×2 23×1; 2011 15×1; 2012 7×1 15×2; 2014 7×8 12×1 15×4; 2015 7×24 15×1; 2018 7×1; 2019 7×1; 2028 7×4 15×4; 2035 7×3 15×3; 2046 23×3; 2048 15×1 23×5; 2049 7×2 15×1 23×3; 3001 12×2 15×2; 3004 12×5 14×2 15×2.

Neither map has a teleport destination (14). The monsters are 9, 58, 3001, 3002 and 3004. That leaves 40 non-monster types across the two maps, and each has a definition, including those that only ever spawn on other skills or in multiplayer.

The populations on Hurt Me Plenty, one player, no monsters:

- Freedoom: 180 things. 5:1 10:3 12:3 15:4 18:5 19:1 20:1 21:2 24:2 26:1 43:12 47:18 48:4 54:15 60:2 2005:1 2007:2 2008:14 2010:1 2011:2 2012:4 2014:30 2015:18 2018:1 2023:1 2028:7 2035:22 2047:1 2048:1 2049:1. The spawn draws P_Random 254 times, the player once and the barrels, bonuses, armour, key and twitching body twice. The three flashes take it to 257, so the index is 1.
- Shareware: 85 things. 10:2 12:2 15:4 24:7 35:2 48:2 2001:1 2007:2 2008:2 2011:1 2012:3 2014:12 2015:25 2018:1 2019:1 2028:8 2035:6 2048:1 2049:3. The random index is 132. This is the sim test's binary run with `BENDOOM_IWAD` set to `doom1.wad`, outside the flake. Its counts, index and first ids equal the nushell replay's.

What was built:

- `src/things.bend` is info.c's slice. It holds 39 spawn-state rows (sprite, frame letter, tics) and 40 definitions (DoomEd type, spawn row, radius and height in map units, vanilla's flags word). A type without a definition does not spawn, which covers the monsters. The spawn walks THINGS in order and threads the random index. A type 1 record draws once for the player. Another record spawns when its options set bit 2 and not bit 16 and its type has a definition. It draws once for P_SpawnMobj, and a state with tics above 0 draws again, lasting that number mod its tics plus 1. A thing flagged 256 hangs its height under the ceiling of the sector under it (type 60, z 60 in sector 153). Every other thing stands on its floor. `Thing` gains `tics`.
- `src/random.bend` holds P_Random, moved out of `sim.bend` because the spawn draws before `sim.bend` exists to import. `State.at` takes the spawn's index instead of counting things.
- `tools/oracle.nu` keeps every THINGS record and writes player 1's start over its record in place. The demo's no-monsters byte keeps monsters from spawning, as `-nomonsters` does, so vanilla draws nothing for them. The `spawned` list is gone. It mirrored Bendoom's table, so it could never catch a type Bendoom forgot.
- Restart already went through `State.start` on the loaded level. The game test's lines now print the thing count and random index. After Enter they are back to 180 and 1, where the play before had drawn the index to 5.
- The ids are record indices, set once at spawn. Filtered records leave gaps (the first ids are 2 6 8 9 10), and nothing renumbers. Removal arrives with pickups in ticket 06. Its law on stable identities stands on this.

Trade-offs:

- **The spawn's random draws came forward from ticket 05.** That means P_SpawnMapThing's second draw and each thing's first tics. The population alone moves the random index. Without the second draw the index would be 73 draws short of vanilla's, the blink lines would be pinned to values no oracle confirms, and the blink frame would differ from Chocolate Doom. With it, the sim test's 20 blink lines equal a nushell replay of T_LightFlash from index 254. The same replay from index 2 gives ticket 01's lines. Ticket 05 keeps next states, the bright bit, per-tic advance and the laws.
- **A row keeps the frame letter only.** The four bright spawn states (CBRA, SOUL, PSTR, COLU) draw with sector light until ticket 05 adds the bit.
- **Sprite clipping tests overlap first.** With 180 things the start view went from 11.3 to 22.4 ms a frame (`bench/frames.bend` at 0 and 500 frames, x86_64 benchmark host, load 3). `Sprites.clip.wall` evaluated the seg-side test for every sprite against every stored range, since `Bool.and` is strict. It now matches on vanilla's first test (a silhouette and a shared column) before anything else. In a second run the frame cost 10.5 ms against ticket 01's 10.0, and no pixel changed.
- The definitions keep radius, height and the whole flags word as info.c has them. This ticket reads only the height and flag 256. Tickets 06 to 09 read the rest.

The oracle, with every thing kept (Freedoom, 20 idle tics unless a script is given):

| case | place | script | differing |
| --- | --- | --- | --- |
| start | -416 256 0 | | 13 |
| lit | 736 464 135 | | 1229 |
| dark | -416 256 90 | | 0 |
| step | 137 256 45 | | 7 |
| grate | -416 256 180 | | 39 |
| water | 3 256 0 | | 0 |
| sky | -640 256 90 | | 0 |
| pit | 488 256 0 | | 13 |
| sergeant | 1144 259 315 | | 448 |
| stride | -416 256 0 | `34,50,0,0,0` | 0 |
| air | -416 256 0 | `56,50,0,0,0` | 3 |
| landed | -416 256 0 | `66,50,0,0,0` | 16 |
| door | 832 384 90 | `20,0,0,0,0 20,25,0,0,0 1,0,0,0,1 20,0,0,0,0` | 41 |
| switch | 2064 -260 90 | `20,0,0,0,0 10,25,0,0,0 1,0,0,0,1 27,0,0,0,0` | 0 |
| blink | 640 712 180 | `66,0,0,0,0` | 0 |
| shareware start | 1056 -3616 90 | | 5 |
| shareware pedestal | -120 -3160 180 | | 871 |
| shareware nukage | 1800 -3300 0 | | 0 |

Each nonzero count is out of this ticket's scope, and two throwaway experiments showed it. The images put every differing pixel on a barrel, a bonus, armour, the twitching impaled body, a column lamp, or the big trees behind the grate. In a copy where both games leave out the animated and full-bright types (Bendoom by skipping them, vanilla by zeroing their options), every case above reports 0 except the grate's 39. Sorting the sprites far to near in that copy makes the grate 0 too. So the rest is animation phase and full-bright (ticket 05) and draw order (ticket 03). The blink case at 0 with everything kept confirms the spawn's draws, since a different index moves sector 33's light. The render test pins the new hashes as regression pins until those tickets, and its header says which.

Checks:

- Every test on both lanes. `bend PROOF.bend` prints "All terms check." The game, the benches and the tools build. `nix flake check` passes.
- The sim test prints the count, the random index, the count of every defined type, the first twelve ids, and six records with their z, sector, row, tics and definition. The six are the first spawned, a chainsaw on floor 194; armour whose first state lasts 5 tics; the leg hung from its ceiling; the blue key, 3 tics; the sergeant; and the last spawned, the berserk pack. Each equals the nushell replay.
- `tests/load.bend` reads the sergeant's sprite at its new row, 6.
