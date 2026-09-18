# 10: Lights blink, strobe and glow

**What to build:** E1M1's lights as p_lights.c runs them. Vanilla's 256-entry random table comes in as a chunked table like the others, its index in the state, 0 at the level's start. Building a state spawns a light thinker for each sector special in sector order, as P_SpawnSpecials does, and they run each tic after the player's movement and before the movers. Special 1 is the random blink: between the sector's light and the lowest neighbouring light, bright for 1 or 65 tics (vanilla masks the random byte with 64) and dark for 1 to 8. Special 12 is the slow strobe in sync: 35 dark, 5 bright, the dark level 0 when no neighbour is darker. Special 8 glows 8 a tic between the sector's light and the lowest neighbouring light. Each writes the sector's light in the state, which the renderer already reads. The oracle tool stops zeroing sector specials.

**Blocked by:** 02 (The oracle plays a demo), 03 (One state the tic maps)

**Status:** resolved

- [x] The random table is taken from linuxdoom's source; closed laws pin its first entries and the first blink's first counts on a literal level
- [x] Closed laws pin the strobe's timeline with and without a darker neighbour, and the glow turning at both ends
- [x] The sim test prints the light of one blinking and one strobing Freedoom sector at chosen tics, computed by hand from the WAD and the table first
- [x] The render test gains a frame of a blinking sector at its dark level
- [x] The oracle, with sector specials left in the PWAD, reports zero at every rest position of the render test and at the new frame; the tool's zeroing of sector specials and the comment about it are deleted
- [x] Glow exists only on the shareware map; the oracle compares one shareware frame of it, count recorded
- [x] Both lanes pass; the flake check stays green

## Comments

Read out of the WADs in nushell and computed by hand before the Bend code answered, from linuxdoom's `p_lights.c`, `p_spec.c` and `m_random.c`:

- `P_Random` steps its index and then reads, so its first answer is `rndtable[1]`, 8. The table begins 0, 8, 109, 220, 222, 241, 149, 107, 75, 248, 254 and ends 249; linuxdoom's and Chocolate Doom's are the same 256 bytes.
- Freedoom: special 1 on sectors 32 (light 176, the lowest around it 144), 33 (176, 140) and 48 (140, 120); special 12 on 90, 96, 98, 147, 150 and 151, each 192 beside a 160. Shareware: special 1 on sector 40 (255, 144), 8 on 44 and 45 (255, 128), 12 on 72 (255, 128).
- The index is 1 when the first light spawns: `P_SpawnMobj` draws once for the player's `lastlook`, the one thing of the oracle's map, before `P_SpawnSpecials`. The three flashes spawn in sector order with entries 2, 3 and 4 (109, 220, 222), each masked with 64, plus 1: 65, 65, 65. All three turn on tic 65 and draw in that order: 241, 149, 107 masked with 7, plus 1: dark for 2, 6 and 4 tics. Sector 32 is bright again on tic 67 (entry 8, 75: 65 tics), sector 48 on tic 69 (248: 65), sector 33 on tic 71 (254: 65). Then 32 dark on 132 (140: 5 tics), 48 dark on 134 (16: 1) and bright on 135 (66: 65), 33 dark on 136 (74: 3), 32 bright on 137 (21: 1 tic, the mask giving 0) and dark on 138 (211: 4), 33 bright on 139 (47: 1), dark on 140 (80: 1), bright on 141 (242: 65), 32 bright on 142 (154: 1), dark on 143. A nushell replay of `T_LightFlash` over the table gave the same lights and counts as the hand run.
- The strobe spawns with count 1, so it is dark after tic 1 through tic 35, bright after 36 through 40, dark again after 41: sector 90 reads 160, 160, 192, 192, 160 on tics 1, 35, 36, 40, 41.
- The glow on the shareware map, 255 over 128: 255 less 8 a tic to 135 after tic 15; tic 16 would reach 127, is undone and turns it; 247 after tic 30; tic 31 would reach 255, is undone and turns it; 191 after tic 38, 135 after tic 45.
- The laws' literal level, the door sector at 160 beside a west room put at 96. Blink: first count 65 (entry 2); dark on tic 65 for (220 & 7) + 1 = 5 tics; bright on tic 70 for 65 (entry 4, 222), the index then 4. Strobe: 96 after tics 1 and 35, 160 after 36 and 40, 96 after 41; with the west room at 160 no neighbour is darker, so 0 after tic 1, 160 after 36, 0 after 41. Glow: 152 after tic 1, 104 after tic 7, tic 8 undone and turned, 112 after 9, 152 after 14, tic 15 undone and turned, 144 after 16. My first run of the glow's numbers put the upper turn a tic late (16); the checker refused it, the recount above is by hand, and the law is written from the recount.

Done. The sim printed every Freedoom light above on its tic the first time (`lights tic ...` in the sim test, sectors 32, 33, 48 and 90 on 21 tics from 0 to 143), and the four closed laws check.

What was built, and where it differs from the ticket's words:

- `Thinker` gained `Blink` and `Glow`. One `Blink` is `T_LightFlash` and `T_StrobeFlash`: a count, a dark and a bright level, a time at each, and whether a time is the count or `P_Random`'s mask. When the count runs out it goes dark from its bright level, else bright (`Sim.blink.to`). A flash's spawn is that same step taken from dark, which is how its first count is drawn, so there is no second copy of the draw. Vanilla's strobe tests the dark level where its flash tests the bright one; the two differ only for a strobe in a sector of light 0, whose levels are both 0, so no light that is written differs. `Glow` is `T_Glow`: a step that would reach an end is undone and turns it, so the light never stands on either end after the first tic.
- The random index starts at 1, not the ticket's 0: Bendoom has no things until milestone 5, and the index is where vanilla's is once the player has spawned. With monsters in the map it will be wherever their spawns leave it; milestone 5 owns that.
- The table is `Tables.rndtable`, generated with the others: `tools/gen_tables.nu` now takes `tables.c` and `m_random.c`, and the other three tables came out byte for byte as they were. `Sim.random` reads it through a tree built on the draw. A draw happens on a flash's turn, a few times a second, so the table is not a field of the geometry, which would have put it in every literal level of the laws.
- Lights spawn in `State.at`, in sector order (`Sim.lights`), so every state a test, a tool or the game builds has them, first in the thinkers' list, where they stay since a light never ends. `State.at` and `State.start` moved below `Sim.extreme`, which the spawn calls. `Sim.mover.kept` and `Sim.door.on` use `State.thinking` where each spelled the append out.
- `Sim.extreme` takes the word's reader (`~L.Level.ceil`, `~L.Level.floor`, `~L.Level.sector.light`) where it took a ceiling flag, so `P_FindMinSurroundingLight` is `Sim.light.low`, the same fold over light. Its four callers changed with it.
- `Sim.moving` passes over lights, as no light sets vanilla's `specialdata`: Freedoom's lift, sector 98, strobes. `Sim.moving`, `Sim.door.turn` and `Sim.pressed.side` each name the one constructor they act on and pass over the rest with one case, where ticket 08 had a case a constructor. `Sim.door.turn.one` went into `Sim.door.turn`; one match fewer.
- `Level.sector.special` and `Level.light.put` beside their kin.
- The sim test's and the game test's `thinkers` counts are each 9 more, Freedoom's nine lights; nothing else in their old lines moved. The render test's `stride U!:34` and `air U!:56` hashes moved, the hall's strobes being dark on tics 34 and 56 (`landed U!:66` did not: no strobing sector is in its view); `blink dark` is new: the wall of sector 33 from 640 712 180 on tic 66, hash 4167308477, which is also the hash of the frame dump's output for that script worked out in nushell, so the pinned frame is the compared one. The dark and the bright frame there differ in 46872 pixels.
- The sim test's `exit` run is `exits` now: the native runtime has an `exit` of its own, and with a run after it the build failed with "two names mangle to FID_EXIT" (the JS lane built). `docs/bend.md` has the constraint.
- `tools/oracle.nu` leaves SECTORS alone; the zeroing and its comment are gone. Line special 48 is still zeroed, ticket 11's.
- The proof check takes about 50 seconds with the four laws, as main's does without them.

Oracle, one shot each, sector specials left in, every Freedoom row and the glow's run again on the lift's commit; the last rebase, over ticket 09's exit, changed no frame's hash:

| WAD | place | script | what | differing |
| --- | --- | --- | --- | --- |
| Freedoom | -416 256 0 | 57 idle | rest | 0 |
| | 736 464 135 | 57 idle | rest | 0 |
| | -416 256 90 | 57 idle | rest | 0 |
| | 137 256 45 | 57 idle | rest | 0 |
| | -416 256 180 | 57 idle | rest | 0 |
| | 3 256 0 | 57 idle | rest, the hall's strobes dark | 0 |
| | -640 256 90 | 57 idle | rest | 0 |
| | 488 256 0 | 57 idle | rest | 0 |
| | 640 712 180 | `66,0,0,0,0` | sector 33's wall at its dark level, the render test's frame | 0 |
| | 640 712 180 | `64,0,0,0,0` | the same wall bright | 0 |
| | -416 256 0 | `25,0,0,0,0 34,50,0,0,0` | the stride | 0 |
| | -416 256 0 | `4,0,0,0,0 56,50,0,0,0` | riding the lift down, whose sector strobes | 0 |
| | -416 256 0 | `90,0,0,0,0 66,50,0,0,0` | off the lift's east edge | 0 |
| | -416 256 0 | `5,0,0,0,0 38,50,0,0,0 110,0,0,0,0` | stopped on the lift in its wait | 0 |
| | -416 256 0 | `53,0,0,0,0 4,0,0,-16,0` | turning | 0 |
| | 832 384 90 | `20,0,0,0,0 20,25,0,0,0 1,0,0,0,1 20,0,0,0,0` | the door half open | 0 |
| | 2064 -260 90 | `20,0,0,0,0 10,25,0,0,0 1,0,0,0,1 27,0,0,0,0` | the switch pressed | 0 |
| | -416 256 0 | `34,50,0,0,0` | the stride on the render test's own tic | 3179, the first of them the water ceiling's blues on the view's top row: its animation's phase, ticket 11's; 0 with the idle first |
| shareware | 464 -3056 225 | `45,0,0,0,0` | sector 44's glow at 135, its dark end | 0 |
| | 464 -3056 225 | `31,0,0,0,0` | at 247, its bright end | 0 |
| | 464 -3056 225 | `38,0,0,0,0` | at 191, going down | 0 |

The two ends of the glow differ in 414 pixels of our frame from there. From 160 -3360 0 the three tics also report 0, but no pixel of the view changes with the glow (the lit ceiling is above the view), so those counts say nothing about it.
