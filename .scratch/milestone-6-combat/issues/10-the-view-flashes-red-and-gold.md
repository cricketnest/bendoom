# 10: The view flashes red and gold

**What to build:** Carry the palette selected by `ST_doPaletteStuff` through the renderer, window, film and frame oracle.

**Blocked by:** 09 (The nukage hurts and the player dies)

**Status:** resolved

- [x] The renderer returns the palette number; the window and film use that PLAYPAL palette
- [x] The oracle compares framebuffer indices, and Chocolate Doom's active palette is checked independently
- [x] A closed law pins damage, bonus and berserk palette boundaries
- [x] Red nukage and gold pickup frames match Chocolate Doom on both WADs
- [x] Neither E1M1 spawns a radiation suit, so no green-palette branch is needed

## Verification

All four frames were rerun against Chocolate Doom 3.1.1 on 2026-09-21, using the integrated native frame binary. Each had zero differing pixels outside the existing pause/face mask. GDB stopped at `I_FinishUpdate` on the same paused tic and read `st_palette` after `ST_doPaletteStuff`; every value equals Bendoom's returned palette.

| WAD | Place | Script | Active palette | Differing pixels |
| --- | --- | --- | --- | --- |
| Freedoom | 1600 1000 90 | `1,0,0,0,0` | 2 | 0 |
| Freedoom | 2246 592 180 | `20,0,0,0,0 1,0,0,-16,0 13,0,-24,0,0` | 11 | 0 |
| Shareware | 1800 -3300 0 | `1,0,0,0,0` | 2 | 0 |
| Shareware | 1791 -3360 90 | `20,0,0,0,0 16,25,0,0,0` | 10 | 0 |

The screenshot palette is not the active palette: vanilla's `V_ScreenShot` passes the first PLAYPAL palette to its PCX writer. `shot_plain` therefore remains true even during a flash. Reading `st_palette` checks the tint without changing or masking framebuffer pixels. A further barrel-death frame at tic 94 independently matched palette 7 with damage count 46.

The `damage_palette` law derives its boundaries from `st_stuff.c`: damage wins over bonus, with the berserk fade raising damage where larger. PLAYPAL contains fourteen 768-byte palettes. The renderer returns `(frame, palette)` so RGB conversion stays in the window/film output, and palette changes do not alter indexed rendering or its geometry laws.

Scratch evidence: `/tmp/m6-palette/oracles.json`, `free-red.log`, `free-gold.log`, `share-red.log`, `share-gold.log` and their GDB scripts. The Freedoom render suite retains its nukage and pickup cases with palette numbers beside the frame hashes.
