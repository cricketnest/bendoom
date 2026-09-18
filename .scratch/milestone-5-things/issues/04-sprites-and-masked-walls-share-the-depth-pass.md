# 04: Sprites and masked walls share the depth pass

**What to build:** Sprites and two-sided middle textures are drawn by one vanilla-order masked pass. A masked wall behind a sprite draws its overlapping columns first. A masked wall in front clips or covers the sprite. Columns already drawn are not drawn again when the pass finishes. The old masked-walls-only pass leaves the codebase rather than surviving beside the replacement.

**Blocked by:** 03 (Sprites obey walls, ledges and each other)

**Status:** resolved

- [x] The masked pass walks visible sprites back to front and stored wall ranges newest to oldest as vanilla does
- [x] A masked range behind a sprite draws only the overlapping columns still pending
- [x] A masked range in front contributes its silhouette clips without drawing behind the sprite
- [x] Remaining masked columns draw once after the last sprite
- [x] The former walls-only traversal is deleted
- [x] Render tests cover both depth orders through a grate or bars
- [x] Chocolate Doom reports zero differing sprite and masked-texture pixels for both orders
- [x] The existing masked-middle-texture frames remain unchanged
- [x] Both lanes pass and the renderer's existing bounds laws stay green

## Comments

The order comes from Chocolate Doom 3.1.1's `r_things.c` (R_DrawMasked, R_DrawSprite) and `r_segs.c` (R_RenderMaskedSegRange). R_DrawSprite scans the drawsegs from the newest. A drawseg that shares no column with the sprite, or has neither a silhouette nor masked columns, is skipped. One behind the sprite (its larger scale under the sprite's, or its smaller scale under it with the sprite in front of the seg) draws its masked columns from r1 to r2 and is not used to clip. Any other clips by its silhouette. R_RenderMaskedSegRange sets each column it draws to SHRT_MAX, so a column is drawn once. R_DrawMasked then draws each drawseg's remaining masked columns, newest first.

What was built:

- `Sprites.masked` is the whole of R_DrawMasked. `Render.rest` calls it alone, and the second traversal it used to run after the sprites is gone.
- The sprites' pass threads the stored ranges. `Sprites.clip.wall` makes vanilla's behind test. `Sprites.clip.side` sends a range behind the sprite to `Masked.wall` over the shared columns, and a range in front to `Sprites.clip.range`, the silhouette clip ticket 03 wrote, now without the behind test. After the last sprite, `Masked.draw` draws what remains.
- `Masked.wall` draws the columns from r1 to r2 whose texture column is not `Masked.drawn()` and returns the range with those columns set to it. `Masked.drawn()` stands for SHRT_MAX. It is 2^31 - 1, a value no texture column takes, since a texture column is a 16.16 value shifted right by 16. The post drawing (`Masked.column`, `Masked.post`) is unchanged.
- A masked range always has a silhouette, since R_StoreWallRange sets both bits for one, so `Sprites.clip.meets` still tests the silhouette alone.

The render cases, found by rendering the frame three ways: this pass; ticket 03's (every sprite, then every masked texture); and a throwaway build that drew every masked texture before the sprites. Neither alternative is committed. Differing pixels in the 320 by 168 view, and the oracle's count for each build:

| case | place | shows | vs ticket 03 | vs masked first | oracle: this pass | oracle: ticket 03 | oracle: masked first |
| --- | --- | --- | --- | --- | --- | --- | --- |
| yard | -640 256 0 | the trees in front of the grate (line 1052) | 837 | 0 | 0 | 628 | 0 |
| bars | 1024 200 0 | a hung body (29) and the dead sergeant (245) behind the AQMETL15 bars at x 1072 | 0 | 516 | 0 | 0 | 516 |
| grate | -416 256 180 | the yard's trees behind the grate, milestone 3's frame | 0 | 286 | 0 | 0 | 212 |

Each wrong order fails at least one case. The bars case also reports 0 after 24 and 31 idle tics. The twitching body (record 172, type 26), which animates only from ticket 05, stays out of the view, so the case does not depend on animation.

The oracle, Freedoom, 20 idle tics:

| case | place | differing |
| --- | --- | --- |
| yard | -640 256 0 | 0 |
| bars | 1024 200 0 | 0 |
| grate | -416 256 180 | 0 |
| once | 256 1088 0 | 0 |
| overlap | 2752 960 0 | 0 |
| walls | 704 256 0 | 0 |
| ledge | 256 128 90 | 0 |

All 21 frames tests/render.bend had before keep their hashes, the grate among them. So every count in ticket 03's table stands.

Ticket 03's two test weaknesses are unchanged, and the shared pass exposes neither end to end:

- A duplicate vissprite has the same scale, rank and id, so it sorts next to its copy. The first copy draws the masked columns behind it, and the second finds none pending and draws the same pixels.
- An equal-scale tie still needs a place free of animated and full-bright things. None that shows a tie also shows a masked texture.

Checks:

- Every test on both lanes (`nix build .#checks.x86_64-linux.tests`: game, load, ranges, render, route, sim and wad_dir, native and js).
- `bend PROOF.bend` prints "All terms check.", renderer laws included (each_in_order, wall_column, silhouettes, plane_span, view_*).
- `nix flake check` passes. `git diff --check` is clean.
- 100 frames natively, x86_64 benchmark host, four runs each: from the start, 1.59 to 1.88 s at ticket 03 and 1.52 to 1.67 s now; from the yard, 1.41 to 1.66 s and 1.45 to 1.56 s. Rebuilding the list of ranges for each sprite costs no measurable time.
