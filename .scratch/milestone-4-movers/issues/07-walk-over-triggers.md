# 07: Walk-over triggers

**What to build:** Lines that fire when crossed. As P_TryMove does, after a move is taken each special line the player's box crossed is tested, newest first, and fires when the player's side of it changed. A once-only line's special is cleared when it fires. Special 2 starts an open-and-stay door on every tagged sector with no thinker: up to 4 under the lowest neighbouring ceiling, where the thinker ends. Special 36 starts a fast floor: down at 4 a tic to the highest neighbouring floor, plus 8 when that is not its own height. Only the shareware map carries 36, so its numbers are pinned by a closed law and checked once by the oracle on the shareware WAD.

**Blocked by:** 04 (Space opens a door)

**Status:** resolved

- [x] The sim test crosses one of Freedoom's special 2 lines and prints the tagged door opening and staying open, heights and tics computed by hand from the WAD first
- [x] Crossing the line again, either way, starts nothing
- [x] A move that touches a special line without changing sides fires nothing; pinned in the sim test or by a closed law
- [x] A closed law on a literal level pins special 36: the destination with and without the 8, and the speed
- [x] The oracle compares a frame of an opened special 2 door on Freedoom and of the lowered floor on shareware, counts recorded, target zero
- [x] The trigger fires from the move that crossed it, inside the tic's movement, so the mover starts on vanilla's tic; the oracle frame one tic after a crossing confirms it
- [x] Both lanes pass; the flake check stays green

## Comments

Read out of the WADs in nushell and computed by hand before the Bend code answered, from `p_doors.c` (`EV_DoDoor` open: up at 2 a tic to 4 under the lowest ceiling around, where the thinker ends) and `p_floor.c` (`turboLower`: down at 4 a tic to the highest floor around, from -500, plus 8 when that is not its own height).

- Freedoom, special 2. Tag 5 (lines 528, 1002 and 1006, one run along y 1472 from x 192 to 512) is sector 77, floor and ceiling -128, the ceilings around it -64 and 64, so its top is -68: 30 tics of travel, -68 after the 30th tic from the crossing, the thinker gone on the 31st. Tag 6 (lines 997 to 999, along x 2032 from y -576 to -256) is sector 145, floor and ceiling 136, the ceilings around it 264, so its top is 260: there after the 62nd tic, gone on the 63rd.
- Shareware, special 36. Line 308 (tag 1) is sector 59, floor 96, the floors around it -48, which is not its own height, so it travels to -40: 136 units at 4 a tic, there after the 34th tic, gone on the 35th.
- The law's literal level: the two-room level with line 0 made special 36 and the door sector's floor put at 16 and its ceiling at 128. Tag 0 is every sector. A player at (60, 64) moving 8 a tic east crosses line 0 on the first tic. Sector 0 (floor 0, the floor across its line 16, not its own): to 24, and a travel down to a height above lands at once, vanilla's instant raise. Sector 1 (floor 16, the floors around 0): to 8, so 12 after the first tic, 8 after the second, its thinker gone on the third. Sector 2 (floor 0, across its line 16): 24 at once. The line's special is 0 from the first tic. A player at (44, 64) moving 6 a tic east ends at 50 with its box across line 0 and its centre still west of it: nothing starts and the special stays 36.

Done. On Freedoom the sim printed the hand computation for tag 6: sector 145's ceiling is 138 on the tic the walk crosses x 2032, 260 on the 62nd tic and its thinker gone on the 63rd; walking back over the line starts nothing. Tag 5's sector 77 read -126 on its crossing and -68 on the 30th tic in `tools/walk.bend`. On the shareware map sector 59 read 92 on the crossing, -40 on the 34th tic.

The law's hand computation was wrong once, and the checker said so: with the east room's ceiling left at 72, the two floors that jump to 24 do not fit the player standing across both lines (72 less 24 is under 56), so vanilla's `T_MovePlane` undoes them and ends their travel all the same, and they stay at 0. That is the re-clip doing its job; the law's level now lifts the east room's ceiling to 128 so that the jump it is about fits, and `turbo_floor_crossed` checks: sector 1 at 12 then 8, sectors 0 and 2 at 24 at once, no thinker on the third tic, the line's special 0 from the first, and for the player whose box is across the line with its centre short of it, no thinker and the special still 36.

What was built:

- `Sim.try_move` adds to the player's `crossed` the special lines the taken move crossed (`Sim.crossings`): two-sided lines with a special that the box at the new place is across, where the centre's side changed, the last gathered first, as vanilla fires its spechit, a line listed in two blockmap cells taken once. It is a pass of its own over the box's lines and not a fourth field of the position check's answer, so the check the wall law stands on is untouched; it looks at a line's special first, so a move near no special line pays for one tree read a line. The player's record carries the list because a tic's movement is several taken moves (halves, slides) and each fires from its own old and new place: working it out from where the tic began and ended would miss a line crossed by more than the radius, which a run does (16.67 a tic against 16).
- `Sim.tic` fires them between use and the thinkers (`Sim.cross`), each by the special it has when its turn comes, so a line cleared earlier in the tic fires nothing; the mover started runs that tic, which the oracle's frame on the crossing tic confirms. The packed player's list is empty again.
- Special 2 is `Sim.door.open`, the manual door's first step alone; special 36 is `Sim.floor.turbo`. Both go through ticket 06's `Sim.tagged` and `Sim.start`, then `Sim.once`, whether or not a sector started, as vanilla clears them.
- The oracle writes a patched copy of the IWAD and no PWAD: Doom refuses `-file` with the shareware IWAD, which ticket 02 never met because it only ran Freedoom. `start-iwad` edits LINEDEFS and SECTORS where they lie, adds the one thing after the directory and points the THINGS entry at it; Freedoom's rest positions still report 0 through it. This is what lets tickets 10 and 11 check the shareware map's glow and scrolling walls.

Oracle, one shot each. The views here are over water or nukage, so each script idles first to a tic where it shows the map's frame (ticket 11 removes the need):

| WAD, place | script | what | differing |
| --- | --- | --- | --- |
| Freedoom, `1960 -450 0` | `41,0,0,0,0 17,25,0,0,0` | the tic of the crossing, sector 145's door 2 up, in view right of centre | 0 |
| | `41,0,0,0,0 18,25,0,0,0` | one tic after | 0 |
| | `41,0,0,0,0 20,25,0,0,0 95,0,0,0,0` | the door open | 0 |
| | `20,0,0,0,0 18,25,0,0,0` (no idle to the water's frame) | | 11312, the water |
| shareware, `3008 -4100 270` | `35,0,0,0,0 16,25,0,0,0` | one tic after crossing line 308 | 0 |
| | `35,0,0,0,0 20,25,0,0,0 45,0,0,0,0` | sector 59 lowered to -40 | 0 |
| | `50,0,0,0,0` | at rest, the first shareware frame ever compared | 0 |
