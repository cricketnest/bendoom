# 11: Animations and scrolling walls

**What to build:** The water and the screens move, and the shareware map's walls scroll. Both are functions of the clock, not state. The animation list is vanilla's, from p_spec.c: an animation exists when the WAD holds its first and last name, and its frames are the flats or textures between them in WAD order, as vanilla counts them. The loader composes every frame of every animation that holds a name the map uses. The renderer translates a flat or texture number through the list at 8 tics a frame, with the phase P_UpdateSpecials would have set on the last tic run: before the first tic the map's own frame shows, and after n tics the phase comes from n less one. A side on a line with special 48 draws with its column offset advanced by one unit per tic run. The oracle tool stops zeroing special 48, and its rest script idles only until the pistol is up.

**Blocked by:** 02 (The oracle plays a demo), 03 (One state the tic maps)

**Status:** resolved

- [x] The animation list is taken from linuxdoom's source; which of its animations each WAD holds, and which E1M1 touches, is read out of the WADs in nushell first and recorded in the comments
- [x] Closed laws pin the translation: the frame at tics 0, 1, 8, 9 and one full cycle on
- [x] The render test's frames at tic 0 keep their hashes; it gains a water frame at a tic that shows another frame of the cycle
- [x] The oracle reports zero at every rest position with the shorter idle, and at the new frame; the 97-tic idle and its explanation are deleted from the tool
- [x] The oracle compares a shareware frame facing a scrolling wall at two tics, counts recorded, target zero
- [x] The tool's header comment no longer says Bendoom reads no specials or does not animate
- [x] The frame rate is measured before and after the translation lookup and recorded; both lanes pass; the flake check stays green

## Comments

Read out of the WADs in nushell and worked out by hand before the Bend code answered. The list is `animdefs` from linuxdoom-1.10's `p_spec.c`: nine flat animations (NUKAGE, FWATER, SWATER, LAVA, BLOOD, RROCK05, SLIME01, SLIME05, SLIME09) and thirteen of textures (BLODGR, SLADRIP, BLODRIP, FIREWALA, GSTFONT, FIRELAV3, FIREMAG, FIREBLU, ROCKRED, BFALL, SFALL, WFALL, DBRAIN), each at 8 tics a frame. A flat's number is its lump's place after F_START, markers counted; a texture's is its place across TEXTURE1 then TEXTURE2. No frame's name is repeated in either WAD (247 lumps after Freedoom's F_START and 963 textures, 57 and 125 in the shareware WAD, all distinct).

- Freedoom holds all 22. Its E1M1 touches four, each by its first frame: NUKAGE1 (flat 122 of 3), FWATER1 (flat 141 of 4), SFALL1 (texture 502 of 4), WFALL1 (texture 494 of 4).
- The shareware WAD holds two: NUKAGE (flat 51 of 3), which its E1M1 touches by NUKAGE3, and SLADRIP (texture 61 of 3), which it does not.
- `P_UpdateSpecials` sets picture `i` to `basepic + (leveltime/8 + i) % numpics`, after the thinkers and before `leveltime++`, so after n tics the time it used is n less one. For Freedoom's NUKAGE1 that is frame (t + 2) mod 3 and for FWATER1 (t + 1) mod 4, t being (n - 1) / 8: after tics 1 to 8 the map's NUKAGE1 shows NUKAGE3 and its FWATER1 shows FWATER2; after the 9th, NUKAGE1 and FWATER3; SFALL1 shows SFALL3 then SFALL4, WFALL1 shows WFALL3 then WFALL4. With the frames numbered first (flats NUKAGE1 to 3 as 0 to 2 and FWATER1 to 4 as 3 to 6, textures SFALL1 to 4 as 1 to 4 and WFALL1 to 4 as 5 to 8), sector 23's floor, sector 36's ceiling and the middles of sides 203 and 932 show 0 3 1 5 at clock 0, 2 4 3 7 at 1 and at 8, 0 5 4 8 at 9, 1 5 4 8 at 41. The flats' texels 0 and 2077 are 123 125 and 206 207 (NUKAGE1, FWATER1) and, at clock 1, 125 125 and 243 207 (NUKAGE3, FWATER2).
- Special 48 is on eight lines of the shareware map, 352 to 359, the sides of the pedestal at (-232, -3232): two-sided, the front sides' upper and lower TEKWALL1, the back sides with no texture at all. Freedoom's E1M1 has none.

Done. The load test printed every number above as computed, the first time.

What was built, and where it differs from the ticket's words:

- The loader numbers every frame of each touched animation ahead of the map's own names (`Gfx.names.after`), so an animation's frames are numbered together in the WAD's order whichever of them the map names; the flats and the textures' composer then take them like any other name. `Gfx.anim.wanted` is the rule: an animation is held when its first name comes before its last among the WAD's names, and touched when the map uses any name between them. Vanilla tests the first frame's name alone and stops with an error when the last frame's is missing; here such an animation is not held. Numbering ahead moved the load test's two pins of raw texture numbers (side 526, the switches), which are pins of the numbering and of nothing outside it.
- The translation is one pure function, `Gfx.anim.shown`, with the ticket's one branch: clock 0 shows the picture itself. `Gfx.of_state` fills two small tables from it each frame, for the animated numbers alone, as `P_UpdateSpecials` fills `flattranslation` and `texturetranslation`; the floor, ceiling, top, bottom and middle lookups read through them, so the renderer's modules did not change for it. A first shape that kept three words a number and did the arithmetic at every lookup cost about 2 ms a frame and was replaced.
- The scroll is `Level.seg.scroll`: the clock in fixed point when the seg's line carries special 48, else 0, added where the side's and the seg's offsets meet in `Segs.geo`. Vanilla moves the front side's offset alone. The shareware map's eight lines have nothing to draw on their back sides, so no map tells a front-only scroll from this one, and the branch is left out.
- `animation_frames` is the closed law: FWATER1 and NUKAGE3 on Freedoom's numbers at tics 0, 1, 8, 9 and a full cycle on (41 and 33). A wrong value in it fails the check.
- The oracle tool no longer zeroes special 48, idles 20 tics by default, and lost the paragraph about 57. With ticket 10's lights merged it zeroes nothing, so `zeroed` went, and `patched` with it, since the one piece left to write, the THINGS entry, is written in place. It also lost `free-display`: every run left its display's lock file behind, runs side by side could pick one number, and once the numbers ran out Chocolate Doom's window never opened. Xvfb now picks its own display (`-displayfd`) and the tool reads it back, and the two jobs are killed when the shot fails too, which used to leave a server running. `parallel.md` lost its advice about idling to tic 57.

Oracle, one shot each, every count from the final tree, rebased on the lift, the exit and the lights, with no special zeroed. Freedoom, the rest positions at the default 20-tic idle:

| place | differing |
| --- | --- |
| -416 256 0 (start) | 0 |
| 736 464 135 | 0 |
| -416 256 90 | 0 |
| 137 256 45 | 0 |
| -416 256 180 | 0 |
| 3 256 0 (under the water, which shows FWATER4; the render test's new `water moving` frame) | 0 |
| -640 256 90 | 0 |
| 488 256 0 | 0 |
| 640 -450 90, facing WFALL1, at 20 and at 29 tics | 0, 0 |
| 2520 1600 90, facing SFALL1, at 20 and at 37 tics | 0, 0 |

The earlier tickets' scripted frames, without their idle prefixes:

| place | script | differing |
| --- | --- | --- |
| start | `34,50,0,0,0` (the stride) | 0 |
| start | `56,50,0,0,0` (riding the lift down) | 0 |
| start | `66,50,0,0,0` (off the lift's east edge) | 0 |
| start | `20,0,0,0,0 4,0,0,-16,0` (turning; a script under 18 tics is refused) | 0 |
| start | `20,25,0,8,0 37,0,-24,0,0` and `20,25,0,8,0 17,0,-24,0,0` | 0, 0 |
| 832 384 90 | `20,25,0,0,0 1,0,0,0,1 20,0,0,0,0` (the door half open), and with its 20-tic idle as the render test pins it | 0, 0 |
| 832 384 90 | `20,25,0,0,0 1,0,0,0,1 115,0,0,0,0` (the door open) | 0 |
| 832 384 90 | `40,25,0,0,0 1,0,0,0,1 61,0,0,0,0 2,25,0,0,0 184,0,0,0,0` and `... 206,0,0,0,0` | 0, 0 |
| 832 384 90 | `40,25,0,0,0 1,0,0,0,1 61,0,0,0,0 6,25,0,0,0 192,0,0,0,0` | 0 |
| 832 384 90 | `40,25,0,0,0 1,0,0,0,1 61,0,0,0,0 6,25,0,0,0 180,0,0,0,0` (163 in ticket 05, a nukage frame off) | 0 |
| 2064 -260 90 | `10,25,0,0,0 28,0,0,0,0` and `10,25,0,0,0 1,0,0,0,1 27,0,0,0,0`, and the second with its idle as pinned | 0, 0, 0 |

The shareware map (`--wad`, kept out of the flake check):

| place | script | differing |
| --- | --- | --- |
| -120 -3160 180, the scrolling pedestal at the view's left, clear of the pistol | 20, 21 and 27 idle tics | 0, 0, 0 |
| 1800 -3300 0, in the nukage the map names by NUKAGE3 | 20 and 29 idle tics | 0, 0 |
| 1056 -3616 90 (its start) | 20 idle tics | 0 |

Between tics 20 and 21, where no animation changes frame (they change after the 16th and the 24th), 60 rows of our frame change at that pedestal, so the scroll alone is in what was compared.

The render test's tic-0 frames keep their hashes. `stride`, `air` and `landed` moved, since animated flats are in view at tics 34, 56 and 66; each new hash is also the hash of the frame dump the oracle found no pixel off, worked out in nushell (FNV-1a over the view's 53760 indices), and so is `water moving`'s.

Frame rate, x86_64 benchmark host, one thread, with the other tickets' agents loading the machine (load average 4 to 6), so the spread between runs is wider than the difference. `bench/frames.bend` at 500 frames less its load, best of six: 9.9 ms a frame before, 10.3 after. `bench/window.bend` on Xvfb, 600 frames, three runs each: 38, 36, 35 frames a second before and 34, 36, 29 after; walking, 37 and 35. Ticket 13 measures on a quiet machine.
