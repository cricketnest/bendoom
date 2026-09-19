# 07: The pistol rises, bobs and shows

**What to build:** The player's weapon appears. The player carries vanilla's two player sprites, weapon and flash, each with a state, tics and a position. The pistol rises at the level's start, rests, and bobs with the player's steps. The renderer draws it after the masked pass at scale one, lit by the player's sector.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] `P_SetupPsprites`, `P_MovePsprites`, `A_Raise` and `A_WeaponReady`'s bob run in the player's think, with state rows for the pistol's ready and raise states
- [x] The sprite is placed and clipped as `R_DrawPSprite` does, with the weapon's patches loaded from the WAD
- [x] The oracle's pistol mask and its rule that a script lasts at least 18 tics are deleted
- [x] Render cases: the pistol mid-rise, at rest, and at two phases of the bob, at zero differing pixels
- [x] Every existing rest and mover frame stays at zero with the pistol compared
- [x] The sim test prints the weapon sprite's state, tics and position on a walk

## Comments

**Where the expected values came from.** Every one was written down before the Bend code answered.

- The rise is p_pspr.c by hand. `P_BringUpWeapon` sets sy to `WEAPONBOTTOM`, 128, and `P_SetPsprite` runs the state's action as it enters the state, so `A_Raise` has already run once when the level starts: sy is 122 on tic 0. Every pistol state has 1 tic, so `P_MovePsprites` enters the next state every tic and `A_Raise` takes 6 more: 116 after tic 1, 38 after tic 14. On tic 15 sy reaches 32, which is not over `WEAPONTOP`, so `A_Raise` sets `S_PISTOL` and `A_WeaponReady` runs in the same tic. `G_PlayerReborn` zeroes the player, so sx is 0 through the rise and `A_WeaponReady` sets it to 1 plus the bob.
- The bob is a nushell replay of `P_SetupPsprites`, `P_MovePsprites`, `A_Raise` and `A_WeaponReady` beside `P_Thrust`, `P_CalcHeight`'s bob and `P_XYMovement`'s friction on open ground, over the finesine table parsed from Chocolate Doom's tables.c. It prints the sim test's eleven lines in `Fixed.show`'s format. The sim test passed against them on its first run, both lanes. The bob is not at its cap on a walk until about tic 30 of it: at tic 48 (28 tics of walking) sy is 47.15, not 48.
- The two closed laws are by hand from the same source: `pistol_rises` (122, 38 after 14 tics, ready at 1, 32 after 15) and `pistol_bobs` (clock 16, a quarter of the 64-tic turn, momentum 30: bob 1048576, cosine -25 gives column 65136, sine 65535 gives row 3145712).
- The patch is read from the WAD in nushell: Freedoom's PISGA0 is 82 by 92 with offsets -125 and -97, the shareware one 57 by 62 with -126 and -106. The load test prints rows 59 and 60 against the Freedoom numbers. By `R_DrawPSprite`, at rest Freedoom's pistol starts at column 126 and its top is at view row 112.5, first row 113. Our frames at tics 14 and 15 differ in 1651 pixels, all inside rows 113 to 167 and columns 136 to 189, and each matches vanilla's frame for its tic, so the oracle sees the pistol and the rise ends on tic 15.
- Regression pins: none in the sim test. In the render test the three hashes that were pins stay pins (below).

**The oracle.** `nix develop -c nu tools/oracle.nu x y degrees script`, frame dump built from this tree. Freedoom, `masked` 665 in every report, which is the pause graphic alone:

| case | place | script | differing |
| --- | --- | --- | --- |
| pistol rising 1 (off the view) | -416 256 0 | `1,0,0,0,0` | 0 |
| pistol rising 8 | -416 256 0 | `8,0,0,0,0` | 0 |
| pistol rising 14 | -416 256 0 | `14,0,0,0,0` | 0 |
| pistol ready 15 | -416 256 0 | `15,0,0,0,0` | 0 |
| start, at rest | -416 256 0 | `20,0,0,0,0` | 0 |
| bob low, tic 48 | -416 256 0 | `20,0,0,0,0 28,25,0,0,0` | 0 |
| bob right, tic 64 | -416 256 0 | `20,0,0,0,0 44,25,0,0,0` | 0 |
| stride (bob far left) | -416 256 0 | `34,50,0,0,0` | 0 |
| air | -416 256 0 | `56,50,0,0,0` | 0 |
| landed | -416 256 0 | `66,50,0,0,0` | 0 |
| lit | 736 464 135 | `20,0,0,0,0` | 0 |
| dark | -416 256 90 | `20,0,0,0,0` | 0 |
| step | 137 256 45 | `20,0,0,0,0` | 0 |
| grate | -416 256 180 | `20,0,0,0,0` | 0 |
| water | 3 256 0 | `20,0,0,0,0` | 0 |
| sky | -640 256 90 | `20,0,0,0,0` | 0 |
| pit | 488 256 0 | `20,0,0,0,0` | 0 |
| sergeant | 1144 259 315 | `20,0,0,0,0` | 0 |
| once | 256 1088 0 | `20,0,0,0,0` | 0 |
| overlap | 2752 960 0 | `20,0,0,0,0` | 0 |
| walls | 704 256 0 | `20,0,0,0,0` | 0 |
| ledge | 256 128 90 | `20,0,0,0,0` | 0 |
| yard | -640 256 0 | `20,0,0,0,0` | 0 |
| bars | 1024 200 0 | `20,0,0,0,0` | 0 |
| door half open | 832 384 90 | `20,0,0,0,0 20,25,0,0,0 1,0,0,0,1 20,0,0,0,0` | 0 |
| switch pressed | 2064 -260 90 | `20,0,0,0,0 10,25,0,0,0 1,0,0,0,1 27,0,0,0,0` | 0 |
| blink dark | 640 712 180 | `66,0,0,0,0` | 0 |
| key 22 | 2380 600 180 | `22,0,0,0,0` | 0 |
| key bright 23 | 2380 600 180 | `23,0,0,0,0` | 0 |
| key before | 2246 592 180 | `20,0,0,0,0 1,0,0,-16,0 12,0,-24,0,0` | 0 |
| key after | 2246 592 180 | `20,0,0,0,0 1,0,0,-16,0 13,0,-24,0,0` | 0 |
| bonus before | 2590 780 90 | `20,0,0,0,0 18,25,0,0,0` | 0 |
| bonus after | 2590 780 90 | `20,0,0,0,0 19,25,0,0,0` | 0 |
| green armour before | 1631 1008 90 | `20,0,0,0,0 11,25,0,0,0` | 0 |
| green armour after | 1631 1008 90 | `20,0,0,0,0 12,25,0,0,0` | 0 |
| stimpack and medikit before | 0 400 90 | `20,0,0,0,0` | 0 |
| stimpack and medikit refused | 0 400 90 | `20,0,0,0,0 16,25,0,0,0 24,-25,0,0,0` | 0 |
| rocket before | 714 -1011 90 | `20,0,0,0,0 1,0,0,16,0 11,0,-24,0,0` | 0 |
| rocket after | 714 -1011 90 | `20,0,0,0,0 1,0,0,16,0 12,0,-24,0,0` | 0 |
| chainsaw after | 3158 2176 180 | `20,0,0,0,0 1,0,0,-16,0 13,0,-24,0,0` | 0 |

That is every frame of the render test that the oracle can compare, each rerun with the pistol compared, and its hash regenerated after the zero. Three hashes are carried on the same draw path with no oracle, as they were before: `exit pressed` (vanilla never stands in it), `rocket refused` and `chainsaw refused` (a full inventory no demo reaches). Their four sampled pixels are unchanged, like every other frame's.

The light is checked where it shows. At scale one the pistol takes `scalelight[lightnum][47]`, which is colormap 0 for any sector light of 144 and over, so only a dim sector tells a wrong light from a right one: `sky` and `yard` stand in sector 29 at light 128 (colormap 5) and `blink dark` in sector 12 at 144 (colormap 1). All three are 0.

The shareware WAD, from its own start, `masked` 762 (its pause graphic): rising 8, rising 14, ready 15, rest, bob low, bob right and the stride, all 0 differing.

**What was built.**

- `src/things.bend`: a state row gains its action, `Thing.Action` with `Null`, `Raise` and `WeaponReady`. Rows 59 and 60 are `S_PISTOL` and `S_PISTOLUP`. `Thing.Weapon{up, ready}` is the part of weaponinfo this ticket reads, and `Thing.pistol()` its one entry.
- `src/sim.bend`: `Psprite{state, tics, sx, sy}` with the state a Maybe, none while the sprite does not show, and `Psprites{weapon, flash}` as the player's last field. `Sim.psprite.set` is `P_SetPsprite` as a loop on fuel: a sprite enters a state, the action runs, and a state the action sets is entered next. Vanilla's actions call `P_SetPsprite` as their last act, so a loop that carries "the state to enter, if any" is the same order of events with no mutual recursion. `Sim.psprite.tic` is `P_MovePsprites` for one sprite and feeds the same loop with the next state when the tics run out. `Sim.psprites` runs both sprites and copies the weapon's place to the flash. It sits in the think between the eye and the counters, where `P_PlayerThink` has it. `Sim.bob` is `player->bob`, now shared by the eye and the weapon; the player does not store it, since the momentum does not change between `P_CalcHeight` and `P_MovePsprites`. `Psprites.start` is `P_SetupPsprites` with `P_BringUpWeapon`, called where the player is made.
- `src/gfx.bend`: the sprite load marks the pistol's raise and ready rows and what they lead to beside the things' rows, so PISGA0 is copied once from whichever WAD is open.
- `src/sprites.bend`: `Sprites.psprite` is `R_DrawPSprite`. It builds a vissprite at scale one and draws it through `Sprites.vis.draw`, the column loop split out of `Sprites.sprite.draw`, with every column unclipped, which the existing column code reads as the view's top and row 168. A sprite wholly off a side has no columns, so vanilla's two early returns need no branch. `Sprites.unclip` is shared with `R_DrawSprite`.
- `src/render.bend`: `Render.psprites` draws the weapon then the flash after the masked pass. `Render.light` is the light number.
- `LAWS.bend`, `PROOF.bend`: the movement laws' literal players carry `Closed.unarmed()`, no sprite showing, which a tic leaves alone, so those laws still compare whole players. `psprites_free` carries the freedom law through the new step of the think. `replay_append` and the other replay laws hold unchanged. Two closed laws were added (above).
- Tests: the sim test's weapon section, the load test's two sprite lines, three render cases (`pistol rising 8`, `pistol bob low 48`, `pistol bob right 64`; the rest case is `start`).

**What was deleted.** `pistol-mask`, the 18-tic rule, the `moves` test that widened the mask, and the header's paragraph about them in `tools/oracle.nu`. The bob's formula written out in `Sim.eye` and again in PROOF's `eye_free`. No source comment said that no weapon shows; the oracle's header was the only place.

**How ticket 11 goes on from here.** A fire state is a row in `Thing.rows` with a new constructor in `Thing.Action` (`FirePistol`, `ReFire`, `Light1`), a field in `Thing.Weapon` for `atkstate` and `flashstate`, and a case in `Sim.psprite.act`. `Gfx.sprite.weapon` chases the new fields so PISGB0, PISGC0 and PISFA0 load. The extra light goes into `Render.light`, which is one expression: add it to the shifted sector light. `Project.shade` already holds the colormap to 0 and 31, so a light number over 15 needs no clamp of its own. The flash already draws when its state is set, full-bright from the row's flag.

**Pulled forward.** The action field on state rows, which the monsters' tickets also need. Nothing else.

**Left for later tickets, by design.** `P_SetPsprite`'s loop over states of 0 tics (no pistol row here has 0 tics; `S_LIGHTDONE` brings it in ticket 11). The -1 tics test in `P_MovePsprites` (no weapon state lasts). `A_WeaponReady`'s fire and change checks and the player's mobj leaving its attack state (tickets 11 and 12). The actions take the clock, the bob and the weapon, which is all these two read; ticket 11's fire action needs the state and will widen that.

**Trade-offs.**

- The pistol's rows are appended as 59 and 60. Vanilla has the weapon states before the things'. Putting them first would renumber every row, every definition's spawn state and the state numbers the sim and load tests print, while three other worktrees are open. The table's comment says the order.
- One `psprites` field on the player, not two sprites and not a wider weapon record. Every `Player{..}` pattern in the sim, the laws and the proof gained it, about 125 places, by one mechanical substitution.
- The flip branch of `R_DrawPSprite` is kept though no weapon lump in either WAD is mirrored, because the WAD decides it.
- The render test's sampled pixels do not fall on the pistol. The hash covers it, and the oracle is what says it is right.

**Surprises.** The old header said the pistol rises for 16 tics. It is 15: the oracle is at 0 on tic 14 with the pistol at 38 and at 0 on tic 15 with it at rest. sx is 0 during the rise and 1 after, so the pistol steps a column to the right as it arrives.

Checks: every test on both lanes; `bend PROOF.bend`; `nix flake check`; `git diff --check`; `doom.bend`, `film.bend`, `tools/walk.bend` and the benches build.
