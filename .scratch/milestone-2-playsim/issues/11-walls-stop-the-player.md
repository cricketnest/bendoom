# 11: Solid walls stop the player through the blockmap

**What to build:** The player cannot leave the map or enter closed rooms. Collision runs through the blockmap so its cost is per cell, not per map: the move's bounding box picks the cells, each cell's line list is walked, the box test rejects lines that cannot touch, and the line side test finds the lines crossed. A one-sided line, or a line flagged blocking even when both sides are open, stops the move; a blocked move leaves the player in place with momentum cleared. Iteration recurses on a shrinking count and post-processes. The sim test walks into a wall and stops.

**Blocked by:** 08 (The player moves)

**Status:** resolved

- [x] Walking into a one-sided wall stops the player short of it, within the player's radius
- [x] A two-sided line flagged blocking stops the player; an unflagged two-sided line does not
- [x] Only the lines in the blockmap cells the move's box touches are tested
- [x] The sim test's scripted list includes a walk into a wall and pins the stopped position
- [x] The step stays pure and takes the tic count; the replay-composition law still proves
- [x] The test passes on both lanes and the flake check stays green

## Comments

Done. The move's box picks the cells (`Sim.lines`), the cells' line lists are concatenated (a line in two cells is tested twice rather than deduplicated with Doom's validcount), and each line goes through the box test, the box side test, and the one-sided or blocking test. The script's "U!:70" and "U!:120" segments run into walls and stop; the replay law still proves.
