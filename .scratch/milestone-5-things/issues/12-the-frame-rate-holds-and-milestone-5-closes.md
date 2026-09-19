# 12: The frame rate holds and milestone 5 closes

**What to build:** Close the milestone with a populated busy view that sustains at least 35 frames a second on the dev machine, the full check green, the roadmap truthful, and no dead path left behind. Review the complete milestone against the spec and the repo's standards. Fix the findings rather than merely recording them.

**Blocked by:** 11 (Both E1M1 routes survive their things)

**Status:** ready-for-human (the maintainer plays both maps to the exit in the window, ticket 11's play-through; the last two boxes wait on it)

- [x] The window bench measures a named scene containing many things plus a running light or mover, with the machine and power state recorded
- [x] The measured rate is at least 35 frames a second; a lower result is fixed in this ticket
- [x] Sprite and thing structures are measured before adding caches, indexes or duplicated lookup tables
- [x] The full flake check passes, including both execution lanes and every proof
- [x] Every oracle count from tickets 01 through 11 is zero or has its explicit out-of-scope cause beside it
- [x] A standards and spec review of the complete milestone is run and every accepted finding is fixed
- [x] The erasure pass deletes the old masked traversal, obsolete one-player-only assumptions, dead definitions and stale comments
- [ ] The README marks milestone 5 done and names decorations, items, pickups and sprites
- [ ] The spec status changes to done only after every earlier ticket is complete

## Comments

**The scene.** A throwaway probe replayed Freedoom's route (ticket 11) and counted the vissprites every tic. The blue key's room holds the most: 52 sprites from its doorway, twice any other view on the route. The bench scene is that doorway. The route runs to the use at tic 591 that opens the room's door, sector 54, then idles 30 tics and walks 3, which leaves the player standing under the door at 2269.43, 232.35 facing 91.4:

    SCRIPT="20,50,0,0,0 1,0,0,-32,0 12,50,0,0,0 1,0,0,32,0 55,50,0,0,0 1,0,0,-64,0 25,50,0,0,0 1,0,0,0,1 34,50,0,0,0 12,0,0,0,0 1,0,0,64,0 20,50,0,0,0 5,0,0,0,0 1,0,0,-64,0 16,50,0,0,0 12,0,0,0,0 1,0,0,64,0 1,0,0,0,1 28,0,0,0,0 8,25,0,0,0 100,0,0,0,0 54,50,0,0,0 14,0,0,0,0 1,0,0,64,0 28,50,0,0,0 1,0,0,0,1 10,-50,0,0,0 10,0,0,0,0 1,0,0,-64,0 12,50,0,0,0 20,0,0,0,0 1,0,0,64,0 83,50,0,0,0 1,50,0,1,1 30,0,0,0,0 3,25,0,0,0" ./window

For all 600 frames the view shows 52 sprites, the key among them running its two states. The door waits, comes down on the player, goes back up, and waits again, about every 160 tics, and the map's blinking lights run in the sim throughout.

**The measurement.** `bench/window.bend` on Xvfb, the game's own loop, 600 frames, one thread as the package runs it, three runs each. x86_64 benchmark host, on mains, `balanced` profile, `powersave` governor with `balance_performance`. The load average stood at 1.0 before and after, from processes outside the bench. The start and the door are milestone 4's scenes and scripts. Milestone 4's binary was built from 6316f1c and run in the same session.

| build | at rest (the start) | the first door | the key room | circling (`WALK=1`) |
| --- | --- | --- | --- | --- |
| milestone 4, its ticket 13 | 41, 38, 40 | 47, 48, 48 | | 46, 46, 46 |
| milestone 4, this session | 41, 41, 41 | 50, 49, 49 | | |
| tickets 01 to 11 (26c16b5) | 39, 39, 38 | 48, 48, 48 | 31, 31, 31 | 47, 47, 47 |
| the seg side asked lazily | | | 32, 33, 32 | |
| ticket 12 | 59, 59, 59 | 59, 59, 59 | 55, 55, 56 | 59, 59, 59 |

The 59s are the runtime's own 60 Hz pacing (`window_pace`). Only the key room shows its real cost, 18 ms a frame.

**Where the key room's 32 ms went.** A throwaway probe timed the renderer over 100 frames of the scene, one stage at a time, with milestone 4's and this build's code. The BSP walk and walls took 7.8 ms, 7.6 ms at milestone 4, and the planes 0.9 ms. Gathering and sorting 52 sprites took 0.13 ms. The sprite pass took 3.4 ms, 2.9 ms of it in the clipping walk over 163 stored ranges. The runtime's window paint took the 14 ms that `.scratch/upstream-bend/issues/01-slow-window-fill.md` measured. perf put half the renderer's time in `term_drop`, reference counts falling as the lookups copy records.

The structures were measured before anything was added, and nothing was added: no cache, index or table.

- **The seg side, asked for every range.** `Sprites.clip.wall` decided behind or in front with a `Bool.or` over R_PointOnSegSide. A call is strict, so every range that met a sprite built its whole seg through `L.Level.seg`, about fifteen tree lookups, whether the scales already decided or not. That was 407 range meetings a frame. `Sprites.clip.behind` now matches on the two scale tests and asks the seg only when the range straddles the sprite's scale, as vanilla's `||` does. The renderer's frame went from 12.1 to 10.9 ms in the key room and 7.5 to 7.0 ms at the start. No pixel changed.
- **Tried and dropped: a masked list apart.** Rebuilding the list of stored ranges for every sprite looked costly. A throwaway split the pass into a read-only clip scan and a short list of masked ranges, the only ones a sprite changes. It saved 0.2 ms for seven more branches, so it was not kept.
- **The window paint.** With the renderer at 10.9 ms, the frame still cost about 31 ms, 32 to 33 frames a second: 14 ms of it was `window_fill` walking the image tree from the root for each of 1.23 million pixels. Upstream issue 01 had the fix and said to patch it locally once the rate became a problem, which it now was. `nix/window-fill.patch`, applied by `nix/bend.nix`, walks the tree once and paints each leaf's square. The window's pixels are unchanged: xwd dumps of the key room, the start and a stride, each shown by a throwaway still-frame program built with either runtime, are byte for byte equal. The issue's status now says it is patched here and still to report upstream.

**The sim's time.** The throwaway probes read the whole state after their runs (every thing's fields, every sector's heights and light, the inventory), since the runtime computes a record's field only when something reads it, and a probe reading the clock alone would miss most of the tic. Native, the same session:

| | milestone 4 | 26c16b5 | ticket 12 |
| --- | --- | --- | --- |
| a level start | 10.3 ms | 16.5 ms | 13.4 ms |
| an idle tic | 0.012 ms | 0.070 ms | 0.042 ms |
| a tic of Freedoom's route | 0.075 ms | 0.172 ms | 0.143 ms |

- **`Things.tics`** flattened the population tree into a list every tic, stepped each thing, and built a new tree. `Thing.tic` reads nothing but its own thing, so `Thing.Tree.tics` maps the tree in place. `Thing.tics` over lists and the rebuild are gone.
- **`Random.at`** built a 256-entry tree from the random table on every call. perf gave it 14% of a level start: the spawn draws for 73 things. It now reads the list.
- **Ticket 09's 50 to 88 ms and 0.22 to 0.39 ms.** Under the same probe, ticket 06's build (90ec563) and ticket 09's (ae01902) start a level in about the same time. Ticket 09's own numbers came from a measure it did not record, so they cannot be compared with these. perf on this build puts 66% of a level start in `Sim.around.go`: each of the nine lights scans all 1175 lines for its neighbours, milestone 4's code. A route tic goes 36% to the line checks, 30% to reference counts, 8% to the things' tic and 8% to the crossings. `Thing.def`'s full scan of the 40 definitions is 0.2%. Nothing past the two fixes above has evidence behind it that a frame would notice. The game runs about one tic a frame.
- **Picks.** Every `Bool.pick`, `Bool.and` and `Bool.or` the milestone added was read. The seg-side test above was the only one over a costly value on a path the frame or tic takes. The load-time ones, over a thing's spawn draw and a sprite's views, cost part of the 13.4 ms start.

**The review.** Two agents reviewed `git diff 6316f1c` apart, one against AGENTS.md and docs/bend.md, one against the spec and tickets 01 to 12 with Chocolate Doom's source.

Fixed from the spec review:

- R_DrawVisSprite's `dc_iscale` is the absolute value of `xiscale`. Bendoom passed the signed step, so a mirrored patch would have sampled its posts upward. No milestone 5 thing shows a rotated frame, so no frame could show it. `Sprites.col.of` takes the absolute value, and `sprite_columns` pins it. Milestone 6's monsters are its first render cases.
- The spec's closed law on sprite-column bounds did not exist. `sprite_columns` projects a thing ahead (columns 128 to 191), one off the left edge (from column 0, 22 columns into its patch), a mirrored one off the right (to 319, from its patch's last column, stepping back), and one past the edge, not drawn, all 160 ahead at scale 1. At 320 ahead, scale 1/2 and a step of 2, it projects a thing ahead (columns 144 to 175) and a mirrored one off the left edge, drawn from column 0 at its patch's column 44 less 1/65536: the last column, 64 less 1/65536, plus the step of -2 times the 10 columns cut. Its column is drawn with `dc_iscale` 2, so passing the scale or the signed step there fails. The expected values are R_ProjectSprite and R_DrawVisSprite worked by hand, the derivation above the law. A typo in one literal made the checker refuse the law, and one false value in each law fails the proof at that law.
- The sort's equal-scale tie had no committed check: `sprite_order` sorts four sprites by R_SortVisSprites' rule.
- A frame with no patches failed with "Sprite TEST frame B has no patches". It now fails with R_InitSprites' own "No patches found for TEST frame B". The test header labels the frame past a sprite's last as a regression pin, since vanilla fails it only in R_ProjectSprite, by numbers.
- Notes false about the code: ticket 05's "nothing takes" the lasting row's `next` (the sprite load's chase reads it and stops there) and its "fifth word a row" (a sixth word in each of a row's eight views). Ticket 11's `I.Inventory.tally`, now `H.Things.tally`. Ticket 03's "vanilla's words", which now lists where vanilla names a lump or sprite by number. The spec's "overflow crashes" (vanilla drops sprites past 128 and ranges past 256) and its oracle that "removes monsters" (it keeps every record and sets the demo's no-monsters byte).
- Unlabelled regression pins: the render test's exit frame and two refused frames, and the sim test's health and armour contact tics.

Fixed from the standards review:

- `Inventory.tally` was the only reason inventory.bend imported things.bend. It is `Things.tally` now, beside `Things.gone`, and callers print `Inventory.show` before it.
- The sim test found a thing by id three times with a linear scan and a flag helper each. All three use `H.Things.get`, three definitions and six branches fewer.
- `Sprites.gather.at` only computed a flag, and is inlined. `Inventory.doubled` walked `Vec`'s constructors outside vec.bend, and is `Vec.doubled`.
- PIT_CheckThing's comment sat on `Sim.touch.stop`. It is on `Sim.touch.def` now.
- `health_bonus` had lost its LAW comment in ticket 09's merge.
- LAWS.bend's `Closed.inv` folds its edits with Base's `List.foldl`, and `radius_within` and `solid_stays` use `List.all` (six branches fewer).

Rejected, with the reason:

- **`Closed.inv`'s edit list.** It keeps its nine named edits. Nine setters or one ten-argument builder would cut the match, but the pickup laws' expected values would become rows of unlabelled numbers, and a law is for the reader to check. Base's `List.map` takes only `&1` lists, so `Closed.ids` stays a recursion.
- **The text helpers.** `Vec.show` and `Inventory.show` stay in src beside their types, as `Fixed.show` and `Angle.show` do. A field added to the record meets its printer there. A shared test module would be the first file under `tests/` that the flake does not run.
- **`Thing.def`'s full scan** walks all 40 definitions because `Thing.def.put` takes the recursion as an argument. An early exit would add a branch for 0.2% of a route tic. `Sim.clear.go`'s full walk is the same, and the freedom proof states Free through it.
- **One solid test for `Sim.blocker.def` and `Sim.touch.def`.** They are PIT_CheckThing's one test read by the check's two passes. Sharing it would compute the overlap twice per thing, or add a definition.
- **Building a vissprite only for a thing shown.** Gathering and sorting take 0.13 ms in the busiest view. A match would add a branch for nothing measurable.
- **The spawn's load-time picks and its two tests of a lasting state.** `tics > 0` is P_SpawnMapThing's and `tics != -1` is P_MobjThinker's, each vanilla's own.
- **Bad frame characters naming the sprite, not the lump's number.** Bendoom has no lump number there. The difference is recorded in ticket 03.
- **Several player 1 starts.** Vanilla makes the last one the player and the earlier ones voodoo dolls. Bendoom takes the first. Each E1M1 has one, so no frame can differ. Recorded here for the milestone that meets such a map.
- **The test helpers `holding` and `full`** are repeated because tests cannot share a module.

**The erasure pass.** Gone in this ticket: `Thing.tics` over lists and the per-tic rebuild of the population tree, the random table's tree rebuilt on every draw, `Inventory.tally` and inventory.bend's import of the things, `Sprites.gather.at`, the sim test's `phased`, `bounds` and `shown` with their scans, `Closed.edits` and the recursive `Closed.within` and `Closed.lasting`, and the runtime's per-pixel paint loop. `Inventory.doubled` moved to `Vec.doubled`. Checked and found already gone: the old masked-walls-only traversal (ticket 04), `Level.blocked`, the oracle's `start-iwad` and `spawned` list, the rotation-0 sprite shortcut. A throwaway scan counted the references to every `def` in src, tests, tools, bench, LAWS.bend and PROOF.bend: every one is used except the laws' fills and `main`. A grep of src, tests, tools, bench, docs, nix and the README for stale claims found none. It covered no things, empty maps or rooms, one player, not spawned, not drawn, no sprite, stand still, masked walls only, walls-only, after every sprite, inert, no monsters, milestone 6, earlier tickets, TODO, FIXME, "for now" and "yet". The two hits, LAWS.bend's "No things." over the empty population and sim.bend's "one player among things that stand still", are true. No scratch tool was committed in this milestone. The benches and tools under bench/ and tools/ are all older, and each is named where it is used.

**The oracle.** Every case of ticket 10's 64-case table and of ticket 11's landmarks on both WADs was rerun on this build, one at a time, with `tools/oracle.nu` (shareware locally, `--wad` set to doom1.wad).

| cases | differing |
| --- | --- |
| ticket 10's table: 59 Freedoom cases (the rest positions, the sprite rules' scenes, the animation and pickup tics, the solid things' scenes, the patched blue door, carried and barrel door cases, the old route at tics 487 and 590) and 5 shareware ones | 0 in each of the 64 |
| Freedoom's route, ticket 11's landmarks at tics 115, 218, 424, 453, 590, 673, 674, 872, 1025, 1110, 1193, 1240, 1261, 1390, 1411, 1435, 1480, 1547 and 1577 | 0 in each |
| Freedoom's route to tic 1578, the exit | 49528: vanilla's intermission, as in ticket 11 |
| shareware route at tics 100, 274, 275, 363, 445, 446, 475, 505 and 644, and milestone 4's unchanged script held by the barrel at 494 | 0 in each |
| shareware route to tic 645, the exit | 48286: vanilla's intermission, as in ticket 11 |

Each landmark's script is the route's commands up to its tic, a run cut where the tic falls inside it.


The shareware route replays locally to the same ending as ticket 11: tic 645, the level ended, 83 things, records 39 and 43 taken, 101 health and 4 shells. The sim test's binary on doom1.wad prints 85 things, random index 132, and 85 links of 85 things, 18 solid of 18, none wrong or unlinked.

**Checks.**

- `nix flake check` passes: the proof prints "All terms check.", and every test passes native and on bun (game, load, ranges, render, route, sim, wad_dir). `nix build .#bendoom .#bendoom-shareware` builds both games with the patched runtime.
- `bend PROOF.bend` after each change. One false expected value in each law this ticket touched or added fails the proof at that law: `radius_within`, `solid_stays`, `health_bonus` (standing for every law on `Closed.inv`), `random_table`, `bonus_cycle`, `sprite_columns` (a signed step down the column) and `sprite_order`.
- Every test native and on bun after each commit, and the render test's hashes unchanged throughout: no frame moved.
- The oracle table above, and the shareware replays, on this build.
- `git diff --check` finds only the patch file's blank context lines.


**The coordinator's review.** `Gfx.tally.fault` built all four of its messages through nested picks; it is a match now, `Gfx.tally.words`, and names the sprite's frame once. `sprite_columns` gained the half-scale and mirrored left-cut cases above; one false value in each of the frac, the column's `dc_iscale` and the half-scale x1 fails the proof at the law. The runtime patch's loop unwraps a level-0 node in a `while` and splits a node in an `if`, and `window_pix`, left to the device kernel, moves under `__CUDACC_RTC__` in `comp.ts`; window dumps of the three scenes are still byte for byte equal and the key room still runs at 56, 55, 56. `Thing.Tree.tics` maps a slot with `Maybe.map` and sits beside the tree's other definitions; `Sprites.clip.behind`'s flags are named for the scales they test; `Things.gone` has its comment back. The spec's story 53 and README condition, this ticket's status, and milestone 4 ticket 10's note on the random table are corrected.

**Decided without the maintainer.**

- **The runtime patch.** Game-side fixes alone left the key room at 32 to 33 frames a second. The walk and walls are milestone 3's code at 7.8 ms, and the paint was 14 ms of the frame. Upstream issue 01 had set the condition for a local patch, and it was met. The cost: `nix/window-fill.patch` must be checked each time the Bend pin moves, and dropped once upstream paints this way.
- **The scene.** It is the busiest view on the route, not the busiest the map could hold. A view picked by hand elsewhere could show more sprites, but no route goes there.
- **The mirrored step** is fixed from vanilla's source and pinned by a closed law. No frame can show it until a spawned thing has rotated frames.
- **The spec's wording.** Its two false lines are corrected in place, not left beside a note.
- **The spec's status** is `ready-for-human`, not `done`, and the README's line says what was built without "Done.", both until the play-through.

**What stays open.** Ticket 11's window play-through: the maintainer plays both maps to the exit in the window. The last two boxes wait on it, so this ticket stays ready-for-human, as milestone 4's ticket 13 did. Until then the README's milestone 5 line names what was built and says it is done once both maps are played to the exit in the window. The spec's status is `ready-for-human`, with that play-through named as its last item. Every other box has its evidence above.
