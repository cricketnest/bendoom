# 11: Both E1M1 routes survive their things

**What to build:** The milestone 4 completion routes are rerun against populated maps and adjusted only where real solid things or pickups make the old commands wrong. Freedoom's route collects the blue key and proves its locked door behavior at landmarks. Both maps still reach the exit with state and frames matching vanilla along the way.

**Blocked by:** 10 (The populated maps match Chocolate Doom)

**Status:** ready-for-human

- [x] Freedoom's route runs from its original player start to the exit through the populated state
- [x] The route records at least one solid-thing collision or avoidance, the blue-key pickup and the locked door after collection
- [x] Inventory, remaining thing count and stable pickup identities are printed at useful landmarks
- [x] Chocolate Doom matches landmark frames and the tic before the exit with zero differing unmasked pixels
- [x] The exit occurs on the same tic in both games
- [x] The shareware route is rerun locally and its adjusted script, landmarks and ending tic are recorded
- [x] Restart restores every collected thing and resets inventory
- [ ] Both maps are played in the window once before the ticket closes
- [x] The Freedoom route passes on both lanes and in the flake check

## Comments

Every expected value came from outside the Bend code: Chocolate Doom's frames, status bar and intermission on the same scripts, the WAD read in nushell, and P_TouchSpecialThing's and PIT_CheckThing's reach worked by hand.

**Freedoom's route**, `tests/route.bend`, in the flake. From the player 1 start, `-416 256 0`, every thing spawned, no record patched, 1578 tics, `Time 0:45`:

    20,50,0,0,0 1,0,0,-32,0 12,50,0,0,0 1,0,0,32,0 55,50,0,0,0 1,0,0,-64,0 25,50,0,0,0 1,0,0,0,1 34,50,0,0,0 12,0,0,0,0 1,0,0,64,0 20,50,0,0,0 5,0,0,0,0 1,0,0,-64,0 16,50,0,0,0 12,0,0,0,0 1,0,0,64,0 1,0,0,0,1 28,0,0,0,0 8,25,0,0,0 100,0,0,0,0 54,50,0,0,0 14,0,0,0,0 1,0,0,64,0 28,50,0,0,0 1,0,0,0,1 10,-50,0,0,0 10,0,0,0,0 1,0,0,-64,0 12,50,0,0,0 20,0,0,0,0 1,0,0,64,0 83,50,0,0,0 1,50,0,1,1 58,50,0,0,0 10,0,0,0,0 1,0,0,47,0 13,0,-24,0,0 1,0,-24,0,0 1,0,0,80,0 60,50,0,0,0 1,0,0,-64,0 71,50,0,0,0 30,0,0,0,0 1,0,0,-64,0 34,50,0,0,0 1,50,0,0,1 44,50,0,0,0 1,0,0,64,0 51,50,0,0,0 20,0,0,0,0 1,0,0,-64,0 9,50,0,0,0 26,0,0,0,0 1,0,0,-50,0 50,50,0,0,0 1,0,0,32,0 10,50,0,0,0 1,0,0,18,0 12,50,0,0,0 10,0,0,0,0 1,0,0,0,1 62,0,0,0,0 20,50,0,0,0 47,50,0,0,0 1,50,0,0,1 20,50,0,0,0 32,50,0,0,0 1,0,0,64,0 60,50,0,0,0 20,0,0,0,0 1,0,0,64,0 15,50,0,0,0 1,50,0,0,1 20,50,0,0,0 24,50,0,0,0 9,0,24,0,0 15,0,0,0,0 21,50,0,0,0 1,0,0,0,1 36,0,0,0,0 8,50,0,0,0 22,0,0,0,0 1,0,0,-64,0 9,50,0,0,0 20,0,0,0,0 1,0,0,0,1

The key sits behind a fence the player cannot cross, in sector 35, whose only way in is the door at 2224 to 2288, 224 from the south-east room; that room is reached from the start over the walkway south of the pit, the south door and the south room's lift, and its row of pillars stands until the special 23 switch lowers them. The pit and the big room beyond it lead on toward the exit, so the key comes first and the route enters the pit by the start's lift on the way back. Each landmark is where a leg of the test ends; its oracle script is the route's first commands up to that tic. The test prints the tic, the player, whether the level has ended, the ceilings of the blue doors, sectors 71 and 51, the whole inventory, the things left and the records taken since the start.

| landmark | tic | player | things, taken | differing |
| --- | --- | --- | --- | --- |
| south door | 115 | 962.67 -127.95 270 | 177: 173 174 175, three armour bonuses, armour 3 | 0 |
| shells | 218 | 1247.89 -438.36 0 | 173: and 207 208 275 276, shells 16 | 0 |
| up the lift | 424 | 2023.39 -470.20 90 | 173 | 0 |
| switch | 453 | 2069.70 -240.05 90 | 173 | 0 |
| key door | 590 | 2270.11 207.54 90 | 173 | 0 |
| key in view | 673 | 2229.78 547.12 157.5 | 173, cards 0 | 0 |
| key taken | 674 | 2227.46 541.59 157.5 | 172: and 87, cards 1, flash 12 | 0 |
| back to the south door | 872 | 962.61 -196.10 90 | 172 | 0 |
| down the start's lift | 1025 | 111.63 249.61 90 | 172 | 0 |
| first door | 1110 | 831.99 490.93 90 | 171: and 264, a health bonus, health 101 | 0 |
| through it | 1193 | 840.97 690.63 90 | 171 | 0 |
| blue door, shut | 1240 | 840.67 1451.67 90 | 171, door 71 at -128 | 0 |
| blue door opening | 1261 | 840.58 1463.95 90 | 171, door 71 at -86 | 0 |
| second blue door, shut | 1390 | -165.93 1776.36 270 | 171, door 51 at -128, door 71 open at -4 | 0 |
| second blue door opening | 1411 | -167.24 1768.05 270 | 171, door 51 at -86 | 0 |
| held by the column | 1435 | -167.14 1642.36 270 | 171 | 0 |
| past the column | 1480 | -237.69 1416.46 270 | 171 | 0 |
| exit room | 1547 | -237.92 1293.20 270 | 171 | 0 |
| exit switch, the tic before the exit | 1577 | -367.94 1283.86 180 | 171 | 0 |
| exit | 1578 | ended | 171 | 49528: vanilla's intermission |

- **Blue key.** Strafed past as in ticket 06, so it is in view the tic before contact. Tic 673 leaves the player 37.78 east and 28.88 south of record 87, outside the reach of 36, its radius 20 and the player's 16. Tic 674 leaves it 35.46 east and 34.41 south, inside, and takes it. Chocolate Doom's frame shows the key at 673 and not at 674, and its status bar gains the blue card on 674.
- **Locked doors after collection.** The route line prints both doors' ceilings at every landmark, and four landmarks stand at the doors. Blue door 71, special 26, is shut at -128 on tic 1240 with the player in front of it. The use on tic 1241, 28.33 short of its line, starts it up at EV_VerticalDoor's 2 a tic: -126 after that tic, -86 at 1261, and the player walks through. It stops at -4, 4 under the ceilings of 0 on both sides, and is there on tic 1390. The map's second blue door, sector 51, lines 520 and 522, also special 26, is shut at -128 on tic 1390, used on 1391 and at -86 on 1411; its neighbours' ceilings are 0 too. Chocolate Doom's frames at 1240, 1261, 1390 and 1411 differ from ours in 0 pixels, each with the door's lower edge in view, so a door 2 units off would differ. The later values, door 71 closing to -58 at 1480 and shut from 1547, door 51 at -38 at 1435 and -4 from 1480, are regression pins of the door code milestone 4's tickets checked by hand. Neither door is tried before the key; ticket 10's planted card compares the refusal, and the window QA below saw door 71 refuse.
- **Solid thing.** Running south through door 51 at x -167.15, the tech column, record 59 at -192, 1600, holds the player at y 1642.36 from tic 1433. The centres are 24.85 apart in x, and the next step would bring them under the 32 of the two radii in y too. A strafe right to -228.71 clears the column, and the run south passes it 40.7 west of it, to the exit room's door.
- **Exit.** The pause after the 1577-tic script finds Chocolate Doom still in the level, 0 differing. After the 1578-tic script the demo's pause tic comes after G_DoCompleted, and the shot is the intermission, `Time :45` as Bendoom's tally. Vanilla's exit is on tic 1578 on both sides, the tic the sim ends the level.
- **Inventory.** Chocolate Doom's status bar at 1577 reads 50 bullets, 101% health, 3% armour, 16 shells and the blue card, the route's last inventory line.

What changed against milestone 4's script: its first door leg keeps its commands, its first turn re-aimed from the new arrival. The ride down now arrives facing 90, so the turn of 14 from 0 becomes -50, the same 19.7° heading. Through it, the exit room, the exit switch and the exit keep theirs unchanged. Its lift leg gives way to the walkway, since the key comes first. Its west door and north room legs give way to the path through both blue doors, and its run south into the column, the leg things made wrong, to the collision and strafe above.

**Restart**, through the real replay seam. After the exit the test hands the ended state to `M.Game.frame` with Enter pressed, as the game's loop does. It prints tic 0, the player at the start, G_PlayerReborn's inventory, 180 things and none taken. It then prints each record the route took, found by comparing the ended state with the start, as the restart left it: `87:24/3 173:18/3 174:18/6 175:18/6 207:41/-1 208:41/-1 264:12/4 275:41/-1 276:41/-1`, state row over tics. The rows are the types' spawn rows, the blue card's, the armour bonus's, the shells' and the health bonus's. The tics are a nushell replay of P_SpawnMapThing on this WAD: one P_Random for every spawned mobj, the player included, and a second, `1 + P_Random() % tics`, for a spawn state of positive tics (the card's 10, the bonuses' 6, green armour's and the barrel's 6, the impaled body's 6), over the rndtable read out of Chocolate Doom's own binary. The replay ends at index 254 with 181 mobjs and gives the sim test's pinned start phases for records 6, 24, 87, 121, 144 and 172 too. Replaying the first leg again takes 173, 174 and 175 on the same tic with the same inventory. A first version compared the restarted population with `S.State.start(level)`, which is the function the restart calls, so it could not fail; the review replaced it with these values. The game test's restart after walking into the key alone is gone, since this case covers it with nine records.

**Shareware**, run locally with `tools/walk.bend` and `tools/oracle.nu --wad` on doom1.wad, kept out of the flake. From `1056 -3616 90`, 645 tics, `Time 0:18`, the same ending as milestone 4:

    20,50,0,0,0 1,0,0,-16,0 70,50,0,0,0 8,50,0,0,0 1,0,0,-48,0 10,50,0,0,0 10,0,0,0,0 1,0,0,0,1 40,0,0,0,0 30,50,0,0,0 1,0,0,-32,0 40,50,0,0,0 1,0,0,56,0 10,50,0,0,0 1,0,0,-24,0 38,50,0,0,0 1,0,0,-60,0 70,50,0,0,0 1,0,0,-32,0 8,50,0,0,0 1,0,0,28,0 30,50,0,0,0 10,0,0,0,0 1,0,0,0,1 40,0,0,0,0 3,0,-40,0,0 50,50,0,0,0 30,0,0,0,0 10,25,0,0,0 10,0,0,0,0 1,0,0,0,1 40,0,0,0,0 17,25,0,0,0 15,0,0,0,0 1,0,0,-64,0 8,25,0,0,0 15,0,0,0,0 1,0,0,0,1 5,0,0,0,0

The one change is milestone 4's `50,50,0,0,0 10,0,0,0,0 3,0,-40,0,0 20,0,0,0,0` after the corridor's door is now `3,0,-40,0,0 50,50,0,0,0 30,0,0,0,0`, the strafe that lines the player up with the exit door moved before the run south. Unchanged, the run south at x 2968.76 is held from tic 471 at y -4284.23 by barrel 48 at 2944, -4320: centres 24.76 apart in x, inside the 26 of its radius 10 and the player's 16, and the next step would close y too. Chocolate Doom plays the unchanged script to the same hold, 0 differing at tic 494. Moved, the run passes the barrel 62.5 east of it, and the strafe also takes shell box 43.

| landmark | tic | player | things, taken | differing |
| --- | --- | --- | --- | --- |
| computer room door | 100 | 1407.51 -2482.93 0 | 85 | 0 |
| before the health bonus | 274 | 2709.21 -2643.88 0 | 85 | 0 |
| health bonus taken | 275 | 2726.05 -2643.50 0 | 84: 39, health 101 | 0 |
| south corridor | 363 | 3048.12 -3633.29 270 | 84 | 0 |
| before the shells | 445 | 2969.76 -3999.55 270 | 84 | 0 |
| shells taken | 446 | 2972.14 -3999.55 270 | 83: and 43, shells 4 | 0 |
| past the barrel | 475 | 3006.54 -4315.32 270 | 83 | 0 |
| lowered floor | 505 | 3008.47 -4615.95 270 | 83 | 0 |
| before the exit | 644 | 2951.89 -4756.26 180 | 83 | 0 |
| exit | 645 | ended | 83 | 48286: vanilla's intermission, `Time :18` |
| unchanged script, held by the barrel | 494 | 2968.76 -4284.23 270 | 84 | 0 |

The health bonus, record 39 at 2752, -2640, is 42.79 ahead at 274 and 25.95 at 275; shell box 43 at 3008, -3968 is 38.24 east at 445 and 35.86 east, 31.55 north at 446. Both are below or behind the view, so the frames cannot show them; Chocolate Doom's status bar goes from 100% to 101% health between 274 and 275 and from 0 to 4 shells between 445 and 446.

**Window QA.** The session was locked overnight, and niri writes no screenshot of a locked session. `niri msg action screenshot-window` returned 0 and saved nothing, so `tools/screenshot.nu` could not be used. The flake's `bendoom` and `bendoom-shareware` ran instead in their windows on a headless Xvfb, keys held with xdotool and the window captured with ImageMagick's `import`; every screenshot was read. Freedoom, played by hand from the start: the start room's corpse and gate; the walkway; the south door opening on Space and the south room beyond; the three armour bonuses in the corridor, one left after running past two; the lift ride into the pit; the first door; the big room; the blue door refusing Space without the key; the west door opening onto the yard with its tech column and health bonuses. Shareware, by hand: the start hall and its pedestal, the corridor to the computer room with its green armour in view. Neither map was played to the exit by hand. Held keys at half a second's resolution kept missing doors in their open time. The exit and restart ran in the game's own loop instead, `bench/window.bend` with each route's script replayed up to the tic before the exit: Space at the switch flipped its texture and ended the level, the loop printed the time, and Enter showed the start again, on both maps. That scripted exit is not a play-through, so the window checkbox stays open.

**What remains:** The maintainer plays both maps to the exit in the window, as milestone 4's ticket 12 left it, and ticks the window checkbox.

Trade-offs, decided without the maintainer:

- **Both blue doors instead of milestone 4's west door.** Keeping the west door and north room legs would have meant opening door 71 and walking back to the west door, and those legs would still need re-aiming from a new arrival. Through door 71, the north room and door 51 is the map's own way to the exit room, and it opens both locked doors.
- **A collision rather than an avoidance at the column.** Running into the column and strafing clear puts the hold in a compared frame. A sim that let the player through would differ from vanilla by thousands of pixels there.
- **Milestone 4's exit legs kept.** They reach the switch 45 tics later than a direct run would, and they are the old script's.
- **The exit's after-frame.** Milestone 4 compared 5 tics after the exit; here the pause comes one tic after it, so the frames before and after pin the exit tic from both sides.
- **Restart in the route test.** It loads the graphics now, to hand the game's frame a real `M.Game`, and replays 2.7 times the tics. It takes 3.4 s native and 5.1 s on bun, against 0.8 and 1.9 s for the blocked route it replaces.
- **One tally line.** `I.Inventory.show` and then `H.Things.tally` (one `I.Inventory.tally` until ticket 12) print the inventory, the things left and the records taken; the sim test's pickup cases, the route test and `tools/walk.bend` all use it, and `tools/walk.bend` now prints it after each run. `V.Vec.show` prints a vector's entries, and `H.Things.gone.name` names a record the population lacks. The sim test's `present` gave way to `H.Things.get`. The sim test's pickup lines now read `things N taken ids` where they read `taken ids things N`; the order moved and no value did. No sim, renderer or pickup behaviour changed.
- **Door heights on every line.** Printing both blue doors' ceilings at every landmark, rather than only at the door landmarks, costs no branch in the test and pins the doors' whole timeline.

Checks:

- Every test on both lanes, `tests/*.bend` native and on bun. Native and bun seconds after the review: game 1.5 and 2.0, load 0.2 and 1.4, ranges 0.2 and 1.3, render 5.6 and 14.8, route 3.5 and 5.0, sim 7.5 and 16.3, wad_dir 0.03 and 0.2.
- `bend PROOF.bend` prints "All terms check."
- `nix flake check` passes. `git diff --check` is clean.
- Both tables above, from `tools/oracle.nu`, one case at a time. After the review only the four door landmarks were rerun (1240 and 1390 are new, 1261 and 1411 unchanged scripts), since no other script or frame changed.
