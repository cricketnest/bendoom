# 01: One decoration reaches the frame

**What to build:** A single real decoration from Freedoom's E1M1 travels through the complete milestone path. The game reads it from THINGS, spawns it into the replay state, loads its sprite patch from the WAD, projects and lights it from the player's eye, draws its transparent posts, and produces the same visible pixels as Chocolate Doom. This is the narrow reference path the rest of the milestone extends.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] One non-solid, non-animated decoration from Freedoom's E1M1 is selected from WAD data and its expected fields are recorded before implementation
- [x] THINGS loading retains signed coordinates, angle, type and options instead of reading only the player start
- [x] A fresh state contains the selected decoration with its map identity, floor position and spawn state
- [x] The WAD's sprite namespace supplies the selected frame and transparent patch posts; no sprite art is baked into Bend
- [x] The renderer projects, lights and draws the decoration at Doom's scale and patch offsets
- [x] A render test prints its frame hash and sampled pixels on both lanes
- [x] The oracle keeps that decoration and reports zero differing sprite pixels at the chosen view
- [x] Existing tests and laws stay green

## Comments

The decoration and its expected values came from outside the Bend code: the WAD read in nushell, and Chocolate Doom 3.1.1's `p_mobj.c`, `info.c`, `r_things.c` and `m_random.c`.

- Freedoom's E1M1 THINGS has 292 records. The decoration is type 19, the dead former sergeant (`MT_MISC67`: spawn state `S_SPOS_DIE5`, `{SPR_SPOS, 11, -1}`, so frame L forever; radius 20, height 16, flags 0, so it is non-solid and stands on the floor). Record 245 is at 1248, 224, angle 90, options 15. The only other type 19 record, 281 at 832, 640, has options 1 (easy skills only), so on Hurt Me Plenty record 245 spawns alone.
- Walking the WAD's nodes in nushell as `R_PointInSubsector` does puts 1248, 224 in subsector 454, sector 170: floor 16 (the top of a bench), light 160.
- The sprite is `SPOSL0`, found between `S_START` and `S_END`: 52 by 20, offsets 26 and 20. Column 0's offset is 216 and holds one post at row 16, one texel long, texel 64. Column 26's offset is 659 and its first post starts at row 1, 17 long, texel 8.
- `P_SpawnMobj` draws `P_Random` for every thing it spawns, the player one of them. The random index is therefore 2 when the lights spawn, not milestone 4's 1. A nushell replay of `T_LightFlash` over Chocolate Doom's table reproduces milestone 4's blink lines from index 1. From index 2 it gives the new ones, which the sim test now expects. The state starts at index 5: two spawns, then the three flashes' first counts.

What was built:

- `Level` keeps THINGS whole: five words a record (x, y, angle, type, options) in `Level.Things`, where `Geo` held the start. Player 1's start is now the first type 1 record, read on demand.
- `src/things.bend` is info.c's slice: the `Thing` record (identity, DoomEd type as `kind`, x, y, z, the sector under it, state row), one state row, one definition, and `P_SpawnMapThing`'s Hurt Me Plenty filter (option bit 2 set, 16 clear). `State` carries the things after the level. `State.at` spawns them, and its random index counts one draw per spawn. Restart rebuilds them from the loaded map.
- The graphics loader copies the sprite lump of each spawned thing's state after the composed columns. `Gfx.sprites` holds each state row's patch index, width and offsets.
- `src/sprites.bend` is `R_ProjectSprite`, `R_DrawSprite` and `R_DrawVisSprite`. It reuses masked.bend's `R_DrawMaskedColumn` and `Segs.colormap` for sprite light.
- `tools/oracle.nu` keeps the records of the types Bendoom spawns (its `spawned` list mirrors `Thing.spawnstate`), replaces player 1's start in place, and runs on Hurt Me Plenty (demo skill byte 2; it was 0).

Trade-offs, and what later tickets inherit:

- **Clipping came forward from ticket 03.** The spawned sergeant shows as one or two pixels past walls in the start, water and stride frames, and the pit frame has it in the field of view but hidden. A decoration drawn without vanilla's visibility would have broken those existing frames. So the BSP walk marks each sector it visits (`Draw.seen`, Doom's validcount), only things in marked sectors are projected, and each sprite is clipped by the stored ranges newest first, with `R_PointOnSegSide` and the silhouette heights. Ticket 03 still owns rotations and mirrored names, sorting with vanilla's ties, and the duplication, overlap, solid-wall and ledge test cases. Sprites are drawn in the order of the things for now.
- **Masked middle textures are drawn after every sprite, whatever the depth.** Ticket 04 replaces this with vanilla's interleaving. No frame here puts the sergeant near a grate.
- Only spawn state rows reach the loader. Ticket 05 follows next-state chains, and ticket 03 replaces the rotation-0 lump name with sprite definitions.
- A thing carries the sector under it (Doom's subsector link), which the spec's field list leaves out: the walk's gathering and the light read it. Angle, tics, floor and ceiling wait for the tickets that read them.
- `type` is a Bend keyword, so the DoomEd type field is `kind` (noted in docs/bend.md).

Checks:

- Chocolate Doom, with the sergeant kept: 0 differing pixels at the new view 1144 259 315 (1630 sprite pixels, none under the pistol mask). Against the old frame dump, which has no sprite, the same case reports 1630, so the zero is the sprite matching.
- 0 at every render test position the oracle plays: start, lit, dark, step, grate, water, sky, pit, stride, air, landed, door, switch and blink. Shareware's start (no type 19 in its E1M1) is also 0.
- The render test gains `sergeant 1144 259 315`. The start, water, stride and water moving hashes changed because vanilla shows the far sergeant there too; the rest are unchanged.
- tests/load.bend prints the THINGS count, three records (player 1's start, the sergeant, one west of the origin), the sprite's width and offsets, and its column 0 and 26 posts read from the draw array. tests/sim.bend prints the fresh state's thing and random index.
- Every test on both lanes, `bend PROOF.bend` ("All terms check."), the game, the benches and the tools build, and `nix flake check` is green.
