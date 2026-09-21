# 04: The status bar shows the inventory

**What to build:** The area under the view becomes Doom's status bar, drawn by the renderer into rows 168 to 199 from the state and the WAD's own graphics: the background, ammo for the ready weapon, health, armour, the arms panel, the keys, and the four ammo counts with their caps. The face's box shows the bar's background until its ticket.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] Every patch comes from the opened WAD, so Freedoom's bar is Freedoom's
- [x] Numbers, percent signs, the minus-free layout and the arms and key slots sit where `ST_createWidgets` puts them
- [x] The blue key shows on the tic it is taken
- [x] The oracle compares rows 168 to 199; its status-bar mask is deleted and a mask over the face's box alone replaces it
- [x] Render cases: the bar at the start, after an ammo pickup, after armour, after the blue key; each at zero differing pixels outside the face's box
- [x] The frame stays a pure function of tables, graphics and state

## Comments

**Where the expected values came from.** Every widget's place is st_stuff.c's `ST_createWidgets` read by hand: the ready weapon's ammo at `ST_AMMOX` 44, `ST_AMMOY` 171, three tall digits; health at 90, 171 and armour at 221, 171, each a percent sign then three tall digits; the arms background at `ST_ARMSBGX` 104, `ST_ARMSBGY` 168; the six arms numbers at `ST_ARMSX` 111 plus `(i % 3) * 12` and `ST_ARMSY` 172 plus `(i / 3) * 10`; the three key slots at 239 and 171, 181, 191; the four ammo counts at 288 and 173, 179, 191, 185, their caps at 314 on the same rows, three short digits each. The rockets' row under the cells' is vanilla's own order, not a slip. `STlib_drawNum` is the right-aligned loop: the last digit sits a zero's width left of x and each digit before it a width further left, so a count of 0 draws one digit because the loop stops on the number and not on the width. `STlib_updateMultIcon` skips a widget whose icon is -1, which is how a colour with neither card nor skull shows nothing, and `ST_updateWidgets` is where a skull beats a card. `V_DrawPatch` in v_video.c is the writer: a patch's posts written at x, y less its own offsets, nothing between them touched.

Patch sizes and offsets were read from both WADs in nushell before the loader answered, and the load test prints nine of them: Freedoom's STTNUM0 and STTNUM1 are both 13 by 16, STYSNUM0 4 by 6, STTPRCNT 13 by 16, STKEYS0 7 by 5, STKEYS3 7 by 7, STGNUM2 4 by 6, STARMS 38 by 32, STBAR 320 by 32. The shareware WAD is why the step is the zero digit's width and not each digit's: its STTNUM1 is 11 wide with a left offset of -1, where its STTNUM0 is 14 wide, and its STKEYS0 has a top offset of -1. `Gfx.s16` reads those offsets signed.

The render test's fifth sampled pixel comes from the WAD too: column 1, row 2 of STGNUM3 is 96 and of STYSNUM3 is 160, so the arms panel's second number reads 96 while the shotgun is not owned and 160 in the two frames with a full inventory.

**The oracle.** `nix develop -c nu tools/oracle.nu x y degrees script`, frame dump built from this tree, every one of ticket 07's cases rerun with all 200 rows compared. Freedoom, `masked` 1595 in every report: the pause graphic's 665 pixels and the face's box, columns 144 to 173 and rows 169 to 199, 930 pixels. Every case reports 0 differing.

| case | place | script | differing |
| --- | --- | --- | --- |
| start, at rest | -416 256 0 | `20,0,0,0,0` | 0 |
| pistol rising 1 | -416 256 0 | `1,0,0,0,0` | 0 |
| pistol rising 8 | -416 256 0 | `8,0,0,0,0` | 0 |
| pistol rising 14 | -416 256 0 | `14,0,0,0,0` | 0 |
| pistol ready 15 | -416 256 0 | `15,0,0,0,0` | 0 |
| bob low, tic 48 | -416 256 0 | `20,0,0,0,0 28,25,0,0,0` | 0 |
| bob right, tic 64 | -416 256 0 | `20,0,0,0,0 44,25,0,0,0` | 0 |
| stride | -416 256 0 | `34,50,0,0,0` | 0 |
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

The four cases this ticket asks for are among them: `start` is the bar at the level's start (50 bullets, 100 health, no armour, no key, the pistol's number yellow and the other five grey), `rocket after` the bar after an ammo pickup (the rockets' count 0 to 1), `green armour after` the bar after armour (0 to 100 behind its percent sign), and `key after` the bar the tic the blue key is taken, its icon in the top slot. No new render case was added, since every frame in the test now carries the bar its state fills.

The shareware WAD, from its own start, 1056 -3616 90, `masked` 1692 (its pause graphic's 762 and the same 930-pixel face box): at rest `20,0,0,0,0`, 8 tics into the rise and the stride `34,50,0,0,0`, all 0 differing. That is the case that checks the zero-width step, since its digits differ in width.

**What was built.**

- `src/bar.bend`: `Bar.patch` is `V_DrawPatch`, a column loop over `Gfx.posts` writing each post down the frame; `Bar.num` is `STlib_drawNum`, `Bar.percent` `STlib_updatePercent`, `Bar.icon` `STlib_updateMultIcon`'s draw; `Bar.keybox` is `ST_updateWidgets`' keyboxes and `Bar.arm` its w_arms choice. `Bar.draw` is `ST_Drawer` with the bar on: `ST_refreshBackground`'s STBAR, then `ST_drawWidgets` in its order.
- `src/gfx.bend`: `Gfx.bar.names()` is the part of `ST_loadGraphics` a single player's bar draws, 35 lumps; they are copied into the array after the sprites, and `Gfx.bar` is the index of each. The array's length grew by their bytes.
- `src/things.bend`: `Thing.Weapon` gains vanilla's `ammo`, the ammotype_t a weapon spends; the pistol's is am_clip.
- `src/sim.bend`: `Player.ready` reads `weaponinfo[player->readyweapon]` for every implemented weapon.
- `src/inventory.bend`: readers for armour, the weapons owned, and a type's rounds and cap.
- `src/render.bend`: `Render.frame` draws the bar over the view's 168 rows. The frame is still a pure function of the tables, the graphics and the state.
- `tools/oracle.nu`: `face-box` is the box the 42 face patches can cover at `ST_FACESX`, `ST_FACESY`, read from the WAD as `patch-pixels` reads the pause graphic.
- `LAWS.bend`, `PROOF.bend`: closed laws `key_boxes` and `arms_numbers`, both worked out from `ST_updateWidgets` by hand.
- Tests: the load test prints nine bar patches' sizes; the render test hashes all 200 rows and samples the arms panel.

**What was deleted.** The oracle's status-bar mask: `168 * 320` is gone from its comparison, its `masked` count and its header. `-devparm` went with it: it binds F1 to the screenshot but also writes 40 frame-rate dots along row 199, over the bar; the extra config binds F1 by itself (scancode 59), so the dots are gone rather than masked. The stale note in `src/show.bend` that the former empty area under the view is a sixth of the window.

**What was pulled forward.** Nothing. `weaponinfo`'s ammo field is this ticket's own need.

**Deliberately absent.** `STlib_drawNum`'s minus sign and its 1994 blank: no count this bar shows is negative. `ST_refreshBackground`'s STMBARL and STMBARR are Doom 1.0's, which neither WAD is, and its face background is a net game's. The frags widget is deathmatch's.

**The frame's cost.** `bench/frames.bend`, 100 frames from the player 1 start folded into the window's image, built from this tree and from HEAD, run eight times each on the dev machine while other agents worked; the lowest of each, which is the least noisy estimate, is 1716 ms before and 1738 ms after. That is 0.22 ms a frame, 17.16 to 17.38, about 1.3 per cent and under one frame a second at 58. Drawing the whole bar every frame therefore needs no cure, and the frame stays pure. Were it ever to matter, the cut is in the window's fold and not in the bar: `Show.fold` descends into the bar's detail every frame where the empty area collapsed to one pixel, and a fold that kept the last frame's image for rows whose pixels did not change would pay for the bar only when a count changes.

**Surprises.**

- Chocolate Doom's `-devparm` writes 40 dots along the last row of the screen, which is the bar's last row. The oracle had always drawn them; they never showed because the mask hid every row of the bar.
- The face's box is the same in both WADs, columns 144 to 173 and rows 169 to 199, though the faces are drawn at 143 and 168: `STFTR00` is 26 wide with a left offset of -3, so the widest face reaches three columns left of the rest and two rows below.
- STBAR covers all 320 by 32 of its rows with no gap in either WAD, so the render test's blank-to-0 and blank-to-255 hashes agree over all 200 rows with nothing else drawn under the bar.

**After the merge.** `milestone-6-7` at 23756e3, the tic command's buttons byte and one `P_PathTraverse`, merged in with no conflict: it touched `Sim`'s think and the sprites' clipping, not the bar's rows, and it left the render test's hashes alone. The merged tree was checked again: every test on both lanes and the proof through `nix flake check` (`all checks passed!`), and six oracle cases rerun against a frame dump built from it, `start`, `key after`, `green armour after`, `rocket after`, `door half open` and `switch pressed`, each 0 differing with `masked` 1595.

That rerun found the one thing worth writing down. A script's buttons field is not the demo's byte: `tools/demo.nu` keeps use at 1 and attack at 2, the demo byte's two low bits traded, so the door and switch cases stay `1,0,0,0,1`. Handing them the demo's 2 fires the pistol instead, and vanilla's bar then reads 49 bullets where ours reads 50, 291 pixels of two tall digits and nothing else. It is a wrong script, and it is also the plainest evidence that the bar counts the ready weapon's ammo.

Checks: the proof (`All terms check.`); the affected tests (load, ranges, route, sounds, demo, sim, game, render) on both lanes before the merge and every test through `nix flake check` after it; 40 oracle cases on Freedoom and 3 on the shareware WAD before, 6 after; `git diff --check`; `doom.bend`, `film.bend`, `tools/walk.bend` and the benches build.
