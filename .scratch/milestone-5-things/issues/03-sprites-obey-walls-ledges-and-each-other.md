# 03: Sprites obey walls, ledges and each other

**What to build:** The populated level's static sprites participate in Doom's visibility rules. The BSP walk gathers each visible sector's things once, projects only those inside the view, sorts them back to front with vanilla's tie behavior, and clips them against wall silhouettes, floors and ceilings. Near sprites cover distant ones and nothing leaks through a wall or ledge.

**Blocked by:** 02 (The non-monster population spawns)

**Status:** resolved

- [x] A sector split across several subsectors contributes each active thing once per frame
- [x] Projection uses the existing 16.16 view transform, near-plane and side culls, patch offsets and reciprocal scale
- [x] Sprite definitions support zero rotations and all eight rotated views, including mirrored lump names
- [x] Visible sprites sort back to front with vanilla's equal-scale choice
- [x] Stored wall silhouettes clip the correct top and bottom columns according to sprite height
- [x] A solid wall fully hides a sprite behind it and a ledge clips only the hidden part
- [x] Overlapping near and far sprites draw in the same order as Chocolate Doom
- [x] Render cases for duplication, overlap, solid-wall hiding and ledge clipping pass on both lanes
- [x] Every oracle case added here reports zero differing sprite pixels

## Comments

Every expected value came from outside the Bend code: the WADs read in nushell, and Chocolate Doom 3.1.1's `r_things.c` (R_InitSpriteDefs, R_InstallSpriteLump, R_ProjectSprite, R_SortVisSprites, R_DrawSprite) and `p_mobj.c` (P_SetThingPosition, P_SpawnMapThing's angle).

- No spawn state of milestone 5 has a rotated frame. In both WADs every spawned row's frame is a rotation 0 lump. Rotations are checked where the WAD has them: PLAY frame A is PLAYA1, PLAYA2A8, PLAYA3A7, PLAYA4A6, PLAYA5, so rotations 8 to 6 are 2 to 4 mirrored; Freedoom's POSS frame A is eight lumps. PLAY's last frame is W.
- A thing's angle is the record's degrees in steps of 45 (`ANG45 * (angle / 45)`). The rotation shown is `(R_PointToAngle(thing) - angle + ANG45 / 2 * 9) >> 29`.
- R_SortVisSprites draws the least scale first. Of equal scales it takes the vissprite made first, because its test is `ds->scale < bestscale` over the list in order. Vissprites are made sector by sector in the walk's first-visit order, and in a sector from its thing list. P_SetThingPosition pushes each thing on the list's head, so the list is newest first.
- Ties are rare, because the fine sine at 0 and 180 degrees is 25 and -25, not 0. Two things on one axis sit at depths a hair apart, and only FixedDiv's truncation at a distance merges their scales. A throwaway scan of the map found tied, overlapping sprites only among the yard's trees (records 269, 271 and 272).

What was built:

- `Thing` gains `angle`, set at spawn from the record. The level already kept the record whole, and ticket 01 left the field to the ticket that reads it.
- The graphics loader builds sprite definitions from the sprite namespace. `Gfx.sprite.def` implements R_InitSpriteDefs for the sprite of a state row. Each lump whose name starts with the sprite's four letters installs its frame and rotation, and a second pair installs mirrored. Every frame from A to the last must be one lump for every side or eight rotations, and there are at most 29 frames. Otherwise the load fails with vanilla's words: no patches, missing rotations, multiple rot=0 lumps, rotations and a rot=0 lump, bad frame characters. A row whose frame is past the sprite's last also fails. The table holds each spawned row's eight views (patch, width, offsets, mirrored). The copy still takes only the lumps those views name. `Gfx.sprite.name`, `states` and `names`, the rotation-0 shortcut, are gone.
- The walk's `Draw.seen` becomes `Draw.Seen`: each sector's rank in the order the walk first reached it. The gather passes over the things once, so a sector split into many subsectors gives each thing once. The rank is also the sort's tie key.
- `Sprites.project` picks the rotation and walks a mirrored patch from its last column with a negative step, as `startfrac = width - 1`, `xiscale = -iscale`. `Sprites.masked` gathers, sorts by `Sprites.before` (scale, then sector rank, then newest id first) with Base's stable merge sort, and draws. The clipping from ticket 01 is unchanged; it already followed R_DrawSprite line by line.
- LAWS.bend gains `sprite_rotation`, a closed law on the rotation rule's samples, proven in PROOF.bend. A false sample makes the checker refuse it.
- tests/load.bend prints the definitions above, built from the real WAD's namespace, and four literal namespaces that vanilla refuses. tests/sim.bend prints each sampled thing's angle.

The render cases. Each place was found by rendering the whole map from a grid of places and angles with throwaway probes, not committed. For each projected sprite, a probe counted its pixels unclipped, clipped by every stored range, clipped by one-sided walls alone, and clipped by floor ledges alone:

- **once 256 1088 0.** The medikit (record 258) is in sector 8. The walk enters it through at least three of its nine subsectors (40, 34 and 35 store ranges), and the medikit shows 300 of its 302 pixels. A second copy would leave the same pixels, so no frame can show duplication. The guard is the gather's shape: it passes over the things once, and not over the sectors' subsectors. The frame also has a near tech column (57) hiding a full-bright column (56) whole.
- **overlap 2752 960 0.** A near stalagmite (153) over a far tree (23): the tree shows 206 of its 1022 pixels. Drawing the sprites in reverse order changes 740 pixels.
- **walls 704 256 0.** One-sided walls alone hide the sergeant (245) and the hung leg (29), both projected. Ledges alone hide two corpses (168, 169).
- **ledge 256 128 90.** A raised bench's edge leaves 78 of a corpse's 220 pixels (171), and one-sided walls alone would leave all 220. The bench hides a second corpse (167) whole.

Trade-offs, and what later tickets inherit:

- **The equal-scale tie has no render case.** Every in-map place where the tie shows also shows an animated health bonus, which differs from vanilla until ticket 05. It is checked with the oracle on a copy of the WAD where both games leave out the animated and full-bright types. At 116 208 135, trees 271 and 269 tie at scale 0.305664 and the copy reports 0. A frame dump built with the tie reversed reports 5 there. On the real WAD, 116 208 135 differs by 4 to 18 pixels at every idle count from 18 to 53 tics, all on the bonuses.
- **Newest id first stands for a sector's thing list.** It holds while things never move between sectors, which is true in milestone 5 (removal keeps the others' order). Milestone 6's moving monsters relink, and the order then needs the list's own history.
- **Masked middle textures still draw after every sprite**, ticket 04's to replace. The yard at -640 256 0 shows it: the grate beyond the trees draws over them, 628 pixels off vanilla's, so it is not a case here.
- The definitions are built and checked for the sprites of spawned rows only. Vanilla checks every sprite in its table, but Bendoom has no table of the sprites it never spawns. Ticket 05's next states extend the same rows.
- Wording: a duplicated rotation reports "is missing rotations" where vanilla says "has two lumps mapped to it", and a rotation past 8 does the same where vanilla reports bad frame characters. Both still fail the load. Where vanilla names a lump or a sprite by number, Bendoom names the sprite: bad frame characters, and a row's frame past its sprite's last, which vanilla meets only in R_ProjectSprite. Ticket 12 gave "no patches" vanilla's words.

The oracle, Freedoom, 20 idle tics unless a script is given:

| case | place | script | differing | ticket 02 |
| --- | --- | --- | --- | --- |
| start | -416 256 0 | | 13 | 13 |
| lit | 736 464 135 | | 1229 | 1229 |
| dark | -416 256 90 | | 0 | 0 |
| step | 137 256 45 | | 7 | 7 |
| grate | -416 256 180 | | 0 | 39 |
| water | 3 256 0 | | 0 | 0 |
| sky | -640 256 90 | | 0 | 0 |
| pit | 488 256 0 | | 13 | 13 |
| sergeant | 1144 259 315 | | 448 | 448 |
| once | 256 1088 0 | | 0 | |
| overlap | 2752 960 0 | | 0 | |
| walls | 704 256 0 | | 0 | |
| ledge | 256 128 90 | | 0 | |
| stride | -416 256 0 | `34,50,0,0,0` | 0 | 0 |
| air | -416 256 0 | `56,50,0,0,0` | 3 | 3 |
| landed | -416 256 0 | `66,50,0,0,0` | 16 | 16 |
| door | 832 384 90 | `20,0,0,0,0 20,25,0,0,0 1,0,0,0,1 20,0,0,0,0` | 27 | 41 |
| switch | 2064 -260 90 | `20,0,0,0,0 10,25,0,0,0 1,0,0,0,1 27,0,0,0,0` | 0 | 0 |
| blink | 640 712 180 | `66,0,0,0,0` | 0 | 0 |
| shareware start | 1056 -3616 90 | | 5 | 5 |
| shareware pedestal | -120 -3160 180 | | 871 | 871 |
| shareware nukage | 1800 -3300 0 | | 0 | 0 |

Sorting took the grate to 0 and the door to 27. With the animated and full-bright types left out of both games, start, lit, step, pit, sergeant, air, landed and door all report 0. What remains is ticket 05's.

Checks:

- Every test on both lanes. `bend PROOF.bend` prints "All terms check." The game, the benches and the tools build. `nix flake check` passes.
- The start view's bench, 100 frames: 1.50 to 1.56 s at ticket 02, 1.49 to 1.65 s now (x86_64 benchmark host). The sort costs no measurable time.

