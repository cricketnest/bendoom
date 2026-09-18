# 13: Sliding along walls

**What to build:** Walking into a wall at an angle slides the player along it, so walls do not feel sticky. When a move is blocked, Doom's slide move finds the blocking line closest along the move, clips the move to it, projects the remaining momentum onto the line and tries again, up to Doom's retry limit, then clears momentum if still blocked.

**Blocked by:** 11 (Solid walls stop the player through the blockmap)

**Status:** resolved

- [x] Walking into a wall at 45 degrees moves the player along the wall at the projected speed
- [x] Walking straight into a wall still stops
- [x] The slide's retry count is a shrinking argument, not a loop
- [x] The sim test's scripted list slides along a wall and pins the position
- [x] The test passes on both lanes and the flake check stays green

## Comments

Done. `Sim.slide` is `P_SlideMove` with two tries then stairstep, as a recursion on fuel over a state record that carries its own done flag. The three corner traces gather lines from the blockmap cells the trace's box touches rather than walking cells with Doom's stepping DDA (which can skip a cell at a corner); the closest blocking intercept, the fudge of 0x800, the projection onto the wall through `R_PointToAngle2` and `P_AproxDistance` are vanilla. The script's "U:100", "S:60" and "A!:40" segments slide along walls.

Second pass after review: the move tried in halves now halves toward zero like C's division (the remainder kept is the shift, as vanilla), and a line flagged two-sided without a back sector blocks the slide as vanilla's empty opening does.
