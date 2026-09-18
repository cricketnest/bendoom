# 12: Fixes from the milestone's code review

**What to build:** The findings of the two-axis review of milestone 3 (standards against AGENTS.md and docs/bend.md; spec against the spec and tickets 01 to 11), each fixed at its cause or answered in a ticket's comments.

**Blocked by:** 11 (At least 35 frames a second)

**Status:** resolved

Done so far, committed with the tree green (all tests on both lanes, all terms check, the game builds):

- [x] `Vec.fixed` deleted (its callers went with the level's new shape); `Vec.of` replaces the two copies of "a list as a tree of its own length"
- [x] `Gfx.build`'s unused `pbases` parameter removed
- [x] The first of `src/sim.bend`'s two "The tic" headers is "The move"
- [x] `tools/screenshot.nu`: xdotool is in the dev shell now; externals called with `^`
- [x] `Project.level` renamed `Project.shade`; `View.coord` so `Bsp.shows` no longer opens the tables; `Level.seg`'s sidedef named as one; `tests/ranges.bend` uses `Render.eye`

Then:

- [x] **Bug (spec review):** `Segs.sil.of` lets a masked texture overwrite the silhouette heights. Vanilla fills in only the missing side: `bsil` is MAXINT when the back ceiling is at or under the front floor; else the front floor when the floor steps down; else MAXINT when the back floor is above the eye or the range is masked. Likewise `tsil`. Nothing reads them until milestone 5, so no frame differs. Fix, and pin with a closed law (a masked range whose floor steps down keeps the front floor as `bsil`)
- [x] `tools/oracle.nu`: a pixel passes when ours equals any shot's value there, instead of dropping every pixel that varies among the shots; comments out of the function bodies (AGENTS.md); `pistol-mask` with `generate` instead of `mut` and `loop`; rewrap the `pcx-indices` comment. Rerun the eight positions and update ticket 10's table
- [x] `bench/window.bend`: the walking run lands in the pit by tic 66 and stands there, so it does not measure walking the opening rooms. Hold up, run and left so the player circles through the start rooms; re-measure; say so in ticket 11. Ticket 11 should also say plainly that the desktop figure is unmeasured (the window was on Xvfb, to keep automated checks off the desktop) and how to take it
- [x] Record story 26 in ticket 10: the shareware `doom1.wad` loads and renders (the reviewer drew its start through `tools/frame.bend`); the oracle cannot run on it, since Chocolate Doom refuses `-file` with the shareware IWAD
- [x] `spec.md` still calls the 168-row view Chocolate Doom's default (its default is screen size 9); correct the two lines
- [x] Judgement calls worth taking: the post walk exists twice (`Gfx.Post` and `Masked.Post`), make it one template; `Planes.none` duplicates `Gfx.none`; `Segs.kind` returns 0, 1, 2 where a three-case type would say solid, window or nothing; `cols` in `Segs.clip` names the solid list; one `Gfx.open` for the IWAD-loading preamble repeated in seven mains; the `Level.room` comment's line wrap in LAWS.bend
- [x] Answered, no change: the silhouette fields and `scale2` have no reader yet because ticket 09 asked that ranges record them as vanilla's drawsegs do; the weakened laws (`tic_rest`, `eye_rest`, the column law on the loop) are recorded in tickets 02 and 06 with the checker's limits that forced them
- [x] Then the flake check once more, and resolve this ticket

## Comments

Done. Every finding is fixed at its cause or answered:

- The silhouette bug is fixed and pinned by the closed law `silhouettes` (ticket 09's addendum).
- `tools/oracle.nu` checks every pixel against all of Chocolate Doom's shots instead of dropping the ones that vary; all eight positions still differ nowhere (ticket 10's table is from the stricter tool). Its comments left the function bodies, the pistol's posts come from `generate`, and it looks the window up again after the wait, since Chocolate Doom sometimes remakes its window while starting, which the rerun met as a BadWindow.
- The walking bench circles the start rooms; the fold merges quadrants of one colour; the frame rate is re-measured on battery (ticket 11's addendum), and the unmeasured desktop figure is said plainly.
- Story 26 is recorded in ticket 10: the shareware WAD renders; the oracle cannot run on it.
- `spec.md` now says screen size 10, not Chocolate Doom's default.
- One post walk, `Gfx.posts`, a template over what is done with each post, serves the composer and the masked pass. `Planes.none` is gone for `Gfx.none`. `Segs.Kind` is solid, window or nothing. `Segs.clip` names the solid list `solids`. `Gfx.open` is the loading preamble seven mains repeated, and their unused imports went with it.
- Kept, with the reason: the silhouette fields and `scale2` have no reader yet because ticket 09 asked that ranges record what vanilla's drawsegs do, for milestone 5; the weakened laws are recorded in tickets 02 and 06 with the checker limits that forced them. Not taken: `shows` repeated in two tests (each test is a program of its own), `Level.sector.light` beside `Level.sector` (the one caller wants only the light), and the record widths as literals at `Level.word`'s call sites (the type's comment is their one definition).
