# 02: One traversal finds what a ray meets

**What to build:** A prefactor. One traversal follows `P_PathTraverse`: it gathers the lines and the things a ray meets through the blockmap, sorts them by distance, and hands each to a visitor that may stop it. The use key becomes its first visitor, and the use key's private line search is deleted.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] Lines and things are intercepted as `PIT_AddLineIntercepts` and `PIT_AddThingIntercepts` do, the thing by its crossing diagonal
- [x] Intercepts come in order of distance, and a visitor's refusal ends the walk
- [x] The use key runs on the traversal, and every use case in the sim and route tests keeps its output
- [x] A literal-level case shows a ray meeting a thing between two lines in the right order, with fractions worked by hand
- [x] The earlier meet, sort and first-hit code of the use key is gone
- [x] Replay composition and the wall law still check

## Comments

### What was built

- `Sim.path` is `P_PathTraverse`, and it is the one traversal: `Sim.path(~A, ~visit, level, lines, things, x1, y1, x2, y2, start)`. The two flags are `PT_ADDLINES` and `PT_ADDTHINGS`. `A` is whatever the visitor carries, and the visitor is `@+level -> @m: Sim.Meet -> @c: A -> Sim.Answer<&2, A>`: it answers whether the walk stops here and what it goes on carrying. The level is threaded by the walk, since every visitor needs it; everything else vanilla keeps in globals lives in `A`.
- `Sim.ray` is the blockmap walk: it takes the origin-relative start and end, works out `mapxstep`, `partial` and the other axis's `step` per axis as `P_PathTraverse` does (`Sim.Axis`), and steps cell by cell, y's intercept before x's, up to 64 cells, ending with the cell the trace ends in. The `done` flag rides in `Sim.Ray` because the checker refuses a loop that matches a computed Bool and then recurses.
- `Sim.meets` gathers cell by cell in the walk's order: a cell's lines (validcount by `Sim.meets.fresh`, which passes over a line an earlier cell listed or this cell listed twice, as the leading zero of a blockmap list makes it) and then the things linked in it. `Sim.meets.sort` is the stable insertion sort that was the use key's, so equal fractions keep the order they were gathered in, which is what `P_TraverseIntercepts`' repeated minimum with a strict `<` picks.
- `Sim.Meet` is vanilla's `intercept_t`: the fraction, whether a line was met, and the name of the line or of the thing. The thing's name is its blockmap identity, which is what tickets 11, 14 and 17 need.
- `Sim.intercept.at` is `P_InterceptVector` over a plain divline; the line version and the thing version both call it. `Sim.intercept.thing` is `PIT_AddThingIntercepts`: `(trace.dx ^ trace.dy) > 0` picks the corner-to-corner diagonal, its ends are tested with `P_PointOnDivlineSide`, and the fraction comes from the same `P_InterceptVector`.
- The use key is the first visitor, `Sim.use.visit`, three lines of `PTR_UseTraverse`. `Sim.use.first` and `Sim.use.first.pick` are gone; `Sim.use` calls `Sim.path` with `Sim.Reach` as its carry.
- The slide is the second, `Sim.slide.visit`, which is `PTR_SlideTraverse`: a line that blocks ends the walk and becomes the slide's when it is nearer than what an earlier corner's trace met. Its carry is `Sim.Slide`, vanilla's `slidemo`, `bestslidefrac` and `bestslideline` in one record. `Sim.trace` keeps its signature, so `PROOF.bend`'s freedom proof needed no change. `Sim.trace.go` is gone.
- One traversal now serves use, `PTR_AimTraverse` and `PTR_ShootTraverse`. Vanilla's `P_SlideMove` calls `P_PathTraverse` too, so the unification is vanilla's own.
- `Sim.keep` is now polymorphic (`~T: Data`), which deleted `Sim.meets.add`, its twin for meetings.
- `H.Thing.Def.radius` joined `things.bend` beside `Thing.Def.kind`: the type's radius in fixed point, which the thing intercept needs and no accessor gave.

### The interface tickets 11, 14 and 17 call

```
Sim.path(~A: Data, ~visit: @+level: L.Level -> @m: Sim.Meet -> @c: A -> Sim.Answer<&2, A>,
  +level: L.Level, lines: Bool, things: Bool, x1: U32, y1: U32, x2: U32, y2: U32, start: A) -> A
```

`A` is the visitor's own record, which holds what vanilla holds in globals (`shootthing`, `shootz`, `attackrange`, `topslope`, `bottomslope`, `aimslope`, `linetarget`, and for the shot the state it spawns puffs into). The visitor answers `Answer{stop, carry}`: `Answer{False{}, c}` is vanilla's `return true` and `Answer{True{}, c}` its `return false`. `Sim.Meet` opens as `Meet{frac, isline, what}`, `what` being the line number when `isline` and the thing's blockmap identity otherwise. Autoaim asks for `True{}, True{}` (both flags), as `P_AimLineAttack` does.

### Where each expected value came from

- The law `ray_meets` is `P_InterceptVector` by hand over the movers' literal level with a barrel linked into its one cell: the west face at 32768 (num -1048576, den -2097152), the barrel at 40960 (num -204800, den -327680) and the east face at 49152 (num 1572864, den 2097152), so the thing falls between the two lines once the sort has run. The arithmetic is in the law's comment. The barrel's radius, 10, is `mobjinfo[MT_BARREL]` in `info.c`, which the thing table already carries.
- The cell walk was checked against `P_PathTraverse` by hand on a scratch program (`/tmp/m6-02/ray.bend`, not in the repo) that prints the cells of a trace. Worked by hand for the diagonal from (32, 64) to (200, 200) with the blockmap origin at 0: `mapxstep` 1, `partial` 49152, `ystep` `FixedDiv(136, 168)` = 53052, `yintercept` 32768 + 39789 = 72557; `mapystep` 1, `partial` 32768, `xstep` `FixedDiv(168, 136)` = 80956, `xintercept` 16384 + 40478 = 56862. In the first cell `yintercept >> 16` is 1 and `mapy` 0, while `xintercept >> 16` is 0 and `mapx` 0, so y steps first; in (0,1) the y test holds and x steps; (1,1) is the last cell. The program prints those three cells. East one cell, east two, east four, north two, both of those reversed and a 2048-unit trace (17 cells, the range ticket 11's hitscan will ask for) all agree with the stepping worked by hand.
- Everything else is a regression: the sim, route and render tests pin what the old search answered, and this ticket changes none of it.

### The oracle

`nix develop -c nu tools/oracle.nu x y degrees script --frame`, the dump built from this tree, Freedoom, `masked` 665 in every report (the pause graphic alone). The cases that lean on the traversal: a use of the first door, a use of the special 23 switch, a run that slides along the corridor walls, the run that ends in the pit, and the plain start. Every one was run twice, before the merge of `milestone-6-7` and again after it, with the same answer.

| case | place | script | differing |
| --- | --- | --- | --- |
| start, at rest | -416 256 0 | `20,0,0,0,0` | 0 |
| stride | -416 256 0 | `34,50,0,0,0` | 0 |
| landed | -416 256 0 | `66,50,0,0,0` | 0 |
| door half open | 832 384 90 | `20,0,0,0,0 20,25,0,0,0 1,0,0,0,1 20,0,0,0,0` | 0 |
| switch pressed | 2064 -260 90 | `20,0,0,0,0 10,25,0,0,0 1,0,0,0,1 27,0,0,0,0` | 0 |

### What was deleted

- `Sim.use.first`, `Sim.use.first.pick`, `Sim.use.before`, `Sim.use.insert`, `Sim.use.sort` (the sort moved to `Sim.meets.*`, unchanged), `Sim.trace.go`, `Sim.meets.add`, and the box gather inside `Sim.meets.at`.
- Milestone 4's ticket 04 left a caveat: "Vanilla orders equal fractions by its cell walk and ours by the box's cells; a trace through a vertex shared by a special and a plain line could pick differently." That is now closed, and the comment that carried it went with the code.
- `Sim.blocks` and `Sim.blocks.open` took a whole `Player` to read three numbers; they take the three.

### The merge

`milestone-6-7` merged in twice with no conflict, since it moved on while this ticket ran: first at 4428326, the tic command carrying fire and the weapon change, which touched `K.Cmd`, the test scripts and six lines of `src/sim.bend`, all in the tic and none in the traversal; then at 66dc9f5, the sounds node, which touched the flake and added `sounds.bend`. `nix flake check` passed before the first merge, after it and after the second (where the proof derivation was already built from the same inputs and only the tests ran). The five oracle cases were rerun on the tree after the first merge.

### Surprises

- `Sim.div_side.slow`, our `P_PointOnDivlineSide`, shifted both factors of each product by eight; vanilla shifts one (`FixedMul(line->dy>>8, dx)` against `FixedMul(dy, line->dx>>8)`). Both sides scaled alike, so the sign was almost always the same, but the truncation and the overflow were not vanilla's. It is now vanilla's. It matters here because `PIT_AddThingIntercepts` calls that function directly, where the line intercepts only reach it for a trace longer than 16 units. No test output moved.
- The box gather could only ever be a superset: a genuine crossing lies on the ray, so its cell is one the walk steps through, and a line the box adds without a genuine crossing has a fraction outside 0 to 1 and is dropped. Vanilla's stepping, on the other hand, can skip a cell the ray clips a corner of, so the walk is the narrower of the two and matches vanilla. Nothing in the tests moved, so nothing in either E1M1 turns on the difference yet.
- A `~` argument may not follow an ordinary one at a call, so a traversal generic over its visitor's carry must take that carry's type as a template too (`~A: Data`), not as a `-A: Kind(a)` parameter. `docs/bend.md` gained that line.
