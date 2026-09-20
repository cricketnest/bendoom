# 10: The view flashes red and gold

**What to build:** The palette flashes. The frame's output carries which of the WAD's 14 palettes is in force, chosen as `ST_doPaletteStuff` chooses: red by the damage count, red by the berserk fade, gold by the bonus count. The window, the film and the oracle read it.

**Blocked by:** 09 (The nukage hurts and the player dies)

**Status:** ready-for-human

- [x] The palette number is part of what the renderer answers, and the window's fold and the film read the chosen palette of PLAYPAL
- [ ] The oracle compares the palette its screenshot carries
- [x] A closed law pins the palette for damage counts and bonus counts at each step's edge
- [ ] Render cases: a red frame after nukage damage and a gold one on a pickup's tic, at zero differing pixels and the same palette
- [x] Neither map spawns a radiation suit, so the green palette has no code

## Deferred to the later pass

- **The oracle cannot compare the tint.** `ST_doPaletteStuff` never touches `I_VideoBuffer`; it calls `I_SetPalette`, which sets the hardware palette alone. `V_ScreenShot` hands `WritePCXfile` the start of the PLAYPAL lump, so a screenshot's 768 bytes of palette are PLAYPAL's first whatever the view is tinted with. Both oracle runs below confirm it: `shot_plain` is true on the gold frame as on the plain one. So the oracle reports the palette Bendoom names and compares the indices under it, which the tint never moves. Comparing the tint itself needs another channel out of Chocolate Doom, which is not tonight's work.
- **The red oracle case in the nukage.** The nukage place is 1600 1000 90, which ticket 08 already put out of the oracle's reach: vanilla's imps in the yard see a player who stands there and chase from the tic they wake, and Bendoom's cannot move yet. The red render case is a regression pin until ticket 16 makes the monsters chase, beside the dead view's from ticket 09.
- **The shareware re-run.** Freedoom alone tonight.

- [ ] A red oracle case in the nukage, once the monsters chase
- [ ] The shareware WAD's frames re-run

## Comments

**Where the expected values came from.** `ST_doPaletteStuff` in Chocolate Doom 3.1.1's `src/doom/st_stuff.c`, worked by hand, with `STARTREDPALS` 1, `NUMREDPALS` 8, `STARTBONUSPALS` 9, `NUMBONUSPALS` 4 and `RADIATIONPAL` 13 from `doomdef.h`. The count is the damage count, raised to the berserk fade `12 - (powers[pw_strength]>>6)` where that is larger; a nonzero count picks `STARTREDPALS + min(7, (cnt+7)>>3)`, an otherwise nonzero flash `STARTBONUSPALS + min(3, (bonuscount+7)>>3)`, and nothing picks 0. Chex Quest's branch and `pw_ironfeet` are not this game's.

The closed law `damage_palette` states all seventeen edges from that reading: counts 0, 1, 8, 9, 64 and the capped 100 pick 0, 2, 2, 3, 8 and 8; flashes 0, 1, 6, 8, 9 and 25 pick 0, 10, 10, 10, 11 and 12; the berserk counter at 1, 256, 768 and 4096 picks 3, 2, 0 and 0, since the fade is 12, 8, 0 and, where vanilla's `int` goes negative, nothing at all; a count of 100 beats the fade, and a flash under a fade of nothing still picks gold.

PLAYPAL is 10752 bytes in Freedoom, 14 palettes of 768, read with `tools/wad.nu`.

**The oracle.** Frame dump built from this tree, Freedoom, `masked` 1595 (the pause graphic and the face's box), `face` 28 in both, which is the face changing under the pause.

| case | place | script | differing | palette | shot_plain |
| --- | --- | --- | --- | --- | --- |
| health bonus before, tic 38 | 2590 780 90 | `20,0,0,0,0 18,25,0,0,0` | 0 | 0 | true |
| health bonus after, tic 39 | 2590 780 90 | `20,0,0,0,0 19,25,0,0,0` | 0 | 10 | true |

The second is the gold case: the frame Bendoom draws on the tic the bonus is taken is vanilla's pixel for pixel, and Bendoom names palette 10 for it. `shot_plain` is the screenshot's 768 bytes against PLAYPAL's first palette; true in both says the screenshot cannot show the tint, which is why the second box is unticked.

**What was built.**

- `src/gfx.bend`: the whole of PLAYPAL, 3584 RGB words, where the first 256 used to sit. `Gfx.colormap()` moves from 65792 to 69120, `Gfx.void()` to 77824 and `Gfx.lumps()` to 77952; nothing else in the layout moves, since the lumps' bases are computed from `Gfx.lumps()`. Thirteen extra kilowords of array.
- `src/bar.bend`: `Bar.palette(damage, strength, bonus)`, `ST_doPaletteStuff` as a pure function of three numbers, with `Bar.fade`, `Bar.red` and `Bar.gold` under it. It lives with the status bar because that is the file `st_stuff.c` became.
- `src/render.bend`: `Render.palette` reads those three off the player, and `Render.frame` answers `Array<U32> & U32`, the frame's indices and the palette they are read through. The palette is bound above the draw, so it is one word live across it and not the player.
- `src/show.bend`: the fold carries the palette and `Show.colour` reads `palette + pal * 256 + index`. `Show.image` now takes the renderer's pair, so `Game.view` and the bench are unchanged. `Show.rgb` is the whole frame's colours for the film.
- `src/inventory.bend`: `Inventory.strength`, the berserk counter.
- `film.bend`: `Show.rgb` in place of its own `Bytes.each` over `Show.colour`.
- `tools/frame.bend`: a first line naming the palette, then the 200 rows.
- `tools/oracle.nu`: reads that line, reports it as `palette`, and reports `shot_plain`, the screenshot's palette against PLAYPAL's first.
- `LAWS.bend`, `PROOF.bend`: `damage_palette`.
- `tests/render.bend`: every line names its frame's palette, and a nukage frame joins the cases.

**What was deleted.** Film's hand-rolled fold of the frame into colours, which `Show.rgb` now is. Nothing else was replaced.

**How later tickets use this.** `R.Render.frame(tables, gfx, s, mem)` answers `(mem, palette)`. Whoever turns indices into RGB destructures that pair: `Show.image` for the window, `Show.rgb` for the film, `Frame.palette` for the dump. The number alone is `Render.palette(player)`, and the arithmetic alone is `Bar.palette(damage, strength, bonus)`, which ticket 12's berserk fist and any later flash can call without a state.

**Trade-offs.**

- The palette travels beside the frame, not inside it. A frame of RGB words would have cost 64000 words of work a tic and lost the oracle its index comparison; a palette written into a slot of the array would have cost a read a pixel and left the frame no longer a pure answer.
- All fourteen palettes are loaded at once, 10752 bytes read instead of 768. Loading the one in force would have made the graphics depend on the state, which is the thing the renderer's purity rests on.
- The render test's every line names its palette rather than two new lines naming it. The palette is part of what a frame is now, and this way the pickup frames that were already there carry the gold evidence for free; the cost is a word threaded through the hash fold and 49 expected lines rewritten with their hashes unchanged.

**Surprises.**

- The run east at tic 66 flashes gold. It has just crossed Freedoom's health bonus record 268 at 512 256, which no case had named before. The frame's hash is unchanged, so this is the palette telling the test something the hash could not.
- A lambda cannot be a template's function where the type reuses its binder. `Bytes.each`'s `~read` is `Array<U32> -> @+i: U32 -> ..`, and a lambda binds affinely: `~(m => i => ..)` is refused with "expected a defined name" naming `Bytes.each`, and `+i =>` does not parse. `Show.rgb` therefore plans the offsets and reads them, which is this codebase's own idiom for reading an array. It is in `docs/bend.md`.
- `3584n` overflowed the checker's stack in one shell and passed in another, so the Nat literal edge moves with the stack the build inherits. `U32.to_nat(3584)` is safe, and `docs/bend.md` says so now.
- Three renderer laws state absolute colormap offsets, so moving the colormaps moved `wall_column`, `sprite_columns` and `plane_span`. Every colormap index in their comments is unchanged; only the base under them moved, from 65792 to 69120.

**The merge.** `milestone-6-7` at 3ce5bba, ticket 05's messages among it. `Render.frame` took a `messages` flag there and answers a palette here, so it has both: the palette is bound above the draw and the pair is made over `Render.hud`'s answer. The render test's `band`, which reads the frame's first eight rows for the message cases, takes the renderer's pair now. `Inventory` gained a `line` field there, so `Inventory.strength` opens twelve fields. The graphics gained the font's lumps, so the palette copy sits beside them with the array sized from `hbases`.

Checks, after the merge: `bend PROOF.bend` prints "All terms check." under `flock /tmp/bendoom-heavy.lock`; every test in `tests/` passes native and on bun; both oracle rows above were run again against a frame dump built from the merged tree, at 0; `git diff --check`.
