# 05: A moving plane re-clips the player

**What to build:** A door that closes on the player goes back up, as vanilla's does. After each step of T_MovePlane the player is re-clipped when inside the moving sector's block box: P_ThingHeightClip through the existing position check recomputes the floor and ceiling under the player, keeps a player who stood on the floor on it, lowers a player whose head is in the ceiling, and answers whether the player still fits. A step the player does not fit is undone and reported crushed, and a crushed normal or blazing door reverses to rising. The block box rule is vanilla's, quirk included: a player inside the box who does not fit for any reason blocks the mover, touching the sector or not. No mover in scope damages.

**Blocked by:** 04 (Space opens a door)

**Status:** resolved

- [x] The sim test opens the first door, stands in the doorway through the wait, and prints the ceiling coming down to the player's head and going back up, at tics computed by hand first
- [x] A closed law on the two-room literal level pins a player on a floor that moves one step: the height follows the floor, the view height does not dip
- [x] A closed law pins the block box rule: a player outside the box is not re-clipped, one inside is
- [x] The oracle compares a frame from under the reversing door, count recorded, target zero
- [x] The re-clip calls the position check the move uses; no second copy of it exists
- [x] The wall law still proves, since the re-clip moves the player only vertically; both lanes pass; the flake check stays green

## Comments

Computed by hand before the Bend code answered. The first door's floor is -128 and the player is 56 tall, so a player in the doorway fits while the ceiling is -72 or more (`P_ThingHeightClip` refuses when ceiling less floor is under the height). Closing from -4 at 2 a tic from the 214th tic after the use: -72 on the 247th; the 248th would make it -74, which does not fit, so the step is undone, the ceiling stays -72, and the door goes back to its plan; -70 on the 249th, -4 on the 282nd, the 283rd lands and the wait starts again.

The laws' literal level: a floor mover on the west room (sector 0) at 4 a tic down: a player standing in it at (32, 64) is in block (0, 0), inside the sector's block box (its one line at x 64 widened by 32 is still column 0, row 0 of a one-cell blockmap), so after one tic the floor, the player's height and the player's floor are all -4, the view height stays 41 with no delta, and the eye is still 41 (it is worked out at the tic's start and follows on the next tic, to 37). A player at (200, 64) is in block column 1, outside the box, and is not re-clipped: height and floor stay 0. A door closing from 68 on a player standing at (72, 64), across both its faces: 56 after 6 tics; the 7th would be 54, which does not fit, so it stays 56 and the thinker is back on its plan; 58 after the 8th.

Done. The sim printed the hand computation: -72 on the 247th tic after the use (tic 287 of the run), -72 again on the 248th, -70 on the 249th, -4 by the 283rd; the two closed laws (`floor_carries`, `door_crushed`) check with the numbers above.

`Sim.reclip` is `P_ThingHeightClip` through `Sim.fit`, the position check the move uses; there is no second copy. After a travel's step writes the plane, `Sim.mover.changed` asks `Level.blocked` (the player's blockmap cell against the sector's block box) and, inside it, re-clips; a step the player does not fit is undone, the player clipped again against the restored plane, and the mover goes back to its plan, which for a door closing is up, hold, down, and for a lift rising will be down, hold, up. Vanilla's `T_MovePlane` leaves one case different, a ceiling rising by a step that is not its last, which it does not undo; a rising ceiling cannot be what makes a player stop fitting, so that case has no state that reaches it and no branch. A blocked step that was the travel's last ends the travel all the same, as vanilla reports `pastdest` there.

The tic's pack now keeps the player's place too: `Player.stood` takes only the height, floor and ceiling from the player the thinkers left, so the wall law needs two one-line facts about it (`stood_x`, `stood_y`) and nothing about any mover. The eye is not touched by the re-clip, as in vanilla, where it is worked out in the player's think at the next tic's start; the law pins that the eye follows a tic late and the view height never dips.

Oracle, one shot each, from the door's south edge facing it (`832 384 90`), a 12-tic idle first so that the nukage in view shows the map's frame on the compared tic (its phase is ticket 11's):

| script | what | differing |
| --- | --- | --- |
| `12,0,0,0,0 40,25,0,0,0 1,0,0,0,1 61,0,0,0,0 2,25,0,0,0 184,0,0,0,0` | the blocked tic, the door's edge at the player's head | 0 |
| `... 2,25,0,0,0 206,0,0,0,0` | 22 tics on, the door going back up | 0 |
| `... 6,25,0,0,0 192,0,0,0,0` (no idle first), from the doorway's north end | the door rising behind the view | 0 |
| `... 6,25,0,0,0 180,0,0,0,0` (no idle first) | the blocked tic from there | 163, all in the nukage flat at the view's right (rows 101 to 108, columns 274 to 309), a frame of its cycle off; 0 with the 12-tic idle first |

The proof check went from 11 to 38 seconds with these two laws: a re-clip in the checker walks the literal level's blockmap and BSP each tic. Ticket 08's lift laws keep the player out of the block box where the law is not about riding.
