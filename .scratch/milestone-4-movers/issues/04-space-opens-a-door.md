# 04: Space opens a door

**What to build:** The tracer bullet: the player walks to E1M1's first door, presses Space, and the door opens, waits and closes as vanilla's. Use is P_UseLines, fired on the press edge after the move and the eye: a trace of 64 units along the facing, its hits sorted by distance, reusing the slide's line gathering and intercept. A line without a special lets the trace go on when its opening is more than zero and stops it otherwise. The first special line ends the trace whatever its special, and acts only from its front side. Specials 1 and 117 start T_VerticalDoor on the sector behind the line: up at 2 a tic (8 for 117) to 4 under the lowest neighbouring ceiling, 150 tics of wait, down to the floor, then the thinker ends. A use on a sector with a running door reverses it: a closing door goes up, any other goes down. Special 26 refuses, silently. The door moves through one T_MovePlane that lands on a destination a step would pass, and writes the ceiling with a path-copying write on the tree, so the position check and the renderer see it with the accessors they have. Thinkers run after the player's movement in the order they were started, so a door used this tic moves this tic.

The player's re-clip under a moving plane is ticket 05; here nobody stands in the doorway.

**Blocked by:** 02 (The oracle plays a demo), 03 (One state the tic maps)

**Status:** ready-for-agent

- [ ] The door's heights and tics are computed by hand first, from the sector heights read out of the WAD in nushell and vanilla's constants, and written into the comments before the Bend code answers
- [ ] The sim test walks to the first door, uses it, and prints the door's ceiling at chosen tics through open, wait and close; a second run uses it again while it closes and again while it waits, and prints the reversal
- [ ] A run holding use for many tics prints one opening; a universal law states that use held across two tics fires on the first alone, and it is proven
- [ ] A run uses a blue key door and prints that nothing moved
- [ ] Closed laws on a literal level of two rooms with a door sector between them pin the ceiling after the first tic, the tic it reaches the top, the tic it starts down and the tic it is shut, for the normal and the blazing door
- [ ] The render test gains a frame with the door half open; the oracle compares it and the door fully open, counts recorded, target zero
- [ ] The player walks through the open door in the sim test, and is stopped by it when shut
- [ ] The wall law and the geometry law still prove; both lanes pass; the flake check stays green
