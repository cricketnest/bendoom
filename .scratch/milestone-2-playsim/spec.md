# Milestone 2: the playsim, one player, no monsters

Status: ready-for-agent

## Problem Statement

Bendoom has a WAD loader and a blank window. Nothing moves. A player of a Doom port expects to walk around E1M1 with the keyboard and be stopped by walls, and expects the movement to feel like Doom: the same speeds, the same slide along a wall, the same turn rate. A reader of the project expects the promise that the player can never pass through a solid wall to be a proven law, not a test.

## Solution

Add the playsim for one player and no monsters: E1M1's map data loaded from the WAD into typed arrays, a 16.16 fixed-point number module on U32 with Doom's angle tables, a pure per-tic step that turns held keys into a tic command and moves the player with Doom's thrust, friction, collision and wall sliding, a top-down debug view of the map so the movement can be seen, and the first real laws: the player's position after any command sequence is free of solid walls, the meaning of "free" is pinned to the map's geometry, and replay composes.

## User Stories

1. As a player, I want to start at E1M1's player 1 start, facing the way the map says, so that the game begins where Doom begins.
2. As a player, I want to walk forward and back with the up and down arrows and W and S, so that I can move through the map.
3. As a player, I want to turn left and right with the left and right arrows, so that I can face where I want to go.
4. As a player, I want to strafe with A and D, so that I can sidestep as in Doom.
5. As a player, I want to hold Shift to run, so that movement speed matches Doom's run.
6. As a player, I want to be stopped by walls, so that I cannot leave the map or enter closed rooms.
7. As a player, I want to slide along a wall when I walk into it at an angle, so that walls don't feel sticky.
8. As a player, I want to step up onto floors up to 24 units higher, so that E1M1's steps are walkable.
9. As a player, I want to be blocked by drops in the ceiling I don't fit under, so that low passages behave as in Doom.
10. As a player, I want lines flagged as blocking to stop me even when both sides are open, so that E1M1's blocking lines hold.
11. As a player, I want movement to advance at 35 tics per second regardless of frame rate, so that speed matches Doom on any machine.
12. As a player, I want the sim to keep pace if a frame takes long, so that a slow frame doesn't slow the game.
13. As a player, I want a top-down view of the map with my position and facing, so that I can see myself move before the 3D view exists.
14. As a player, I want the debug view to show one-sided walls and two-sided lines differently, so that I can read the map.
15. As a player, I want Esc or closing the window to quit, so that I can leave at any time.
16. As a player, I want to play with Freedoom's first map as well as the shareware E1M1, so that no proprietary data is needed.
17. As a proof author, I want the sim step to be a pure integer function of a command, the level, and the player, so that laws can be stated about it.
18. As a proof author, I want a law that replaying any command sequence from the start leaves the player at a position that is free of solid walls, so that the wall promise is proven, not tested.
19. As a proof author, I want a law that pins what "free" means against the map's linedefs, so that the wall law is not tautological.
20. As a proof author, I want a law that replaying two sequences in turn equals replaying their concatenation, so that demos and netcode can rely on it later.
21. As a proof author, I want laws that fixed-point multiply by one is the identity and that it commutes, so that the number module is trusted.
22. As a proof author, I want a law that the fixed-point multiply equals the exact product shifted right by sixteen, so that the split-word implementation is checked against its spec.
23. As a proof author, I want laws that key presses fold as in Doom (the last press of a key wins, arrows and WASD map to the same bits), so that input has no surprises.
24. As a developer, I want the map lumps parsed into arrays indexed by number, so that lookups are O(1).
25. As a developer, I want the blockmap loaded and used for collision, so that collision costs are per cell, not per map.
26. As a developer, I want Doom's sine and tangent tables with the exact vanilla values, so that thrust vectors match Doom.
27. As a developer, I want the sim step to take the number of tics to run as an argument, so that tests are deterministic.
28. As a developer, I want a test that loads E1M1 from the WAD, runs a scripted command list and prints the resulting position, so that movement is checked at the program's own boundary.
29. As a developer, I want the tests to pass on both the JS lane and the native binary, so that both backends stay usable.
30. As a developer, I want a measured comparison of emulated signed fixed-point against F32 in a representative loop, so that the renderer decision in milestone 3 rests on a number.
31. As a packager, I want the WAD test to run in the flake check against Freedoom, so that the build proves the loader works, not just the proofs.
32. As a packager, I want the flake to keep building with no new inputs, so that the build graph stays five nodes.

## Implementation Decisions

- The number module represents Doom's fixed_t as two's complement on U32 with sixteen fraction bits. Signed compare, negate, absolute value, add and subtract are defined on top of U32's wrapping arithmetic. Multiply splits each operand into two 16-bit halves so the 64-bit intermediate never exists; divide follows Doom's saturating FixedDiv, including its overflow guard. Integer map coordinates (signed 16-bit in the WAD) convert to fixed by sign extension then shift.
- Angles are Doom's binary angle measure on U32, where wraparound is native. The fine sine and tangent tables carry the exact values from vanilla tables.c, produced once by a checked-in generator script and stored as a Bend source module; the sim never calls a float function. If a literal table that large compiles too slowly, the fallback is a binary table file read through the byte-reading effect.
- The level is one record of arrays: vertices, linedefs, sidedefs, sectors and the blockmap, each parsed from its lump at load into a flat array. The things lump is read only for the player 1 start. Level geometry is a parameter of every sim function and never part of the state, so no law is needed to say replay leaves the map unchanged.
- The player state is position, angle, momentum and the held-key word. A tic command is forward move, side move and turn, built from held keys with Doom's speed tables (walk and run values, turn speed with the two-tic slow-turn ramp).
- One tic step is pure and follows Doom's order: build the command, thrust, XY movement with friction, collision through the blockmap with the box test and line side test, step-up and ceiling checks through openings, and the slide move when blocked. No mutual recursion: iteration over blockmap cells and their line lists recurses on a shrinking count and post-processes.
- "Free" is a decidable predicate over the level and a position: no solid line comes within the player's radius. The wall law is proven by an invariant preserved by the step; the second law states that the predicate's answer implies the geometric distance condition for every solid line, certified over the finite line list by computation. If certification over the whole list is too slow for the checker, it is split per blockmap cell.
- The app layer owns time: it reads the clock, computes elapsed tics at 35 per second with an accumulator, and calls the pure step that many times, capped so a stall cannot snowball. Frames stay paced at the runtime's 60 Hz.
- The debug view draws map lines and the player into a flat framebuffer array with integer line drawing, then folds it into the frame quadtree. It is throwaway and gets replaced by the wall renderer in milestone 3.
- Key codes follow the runtime's table: Esc 27, arrows 63232 to 63235, letters as lowercase ASCII, Shift by its code.

## Testing Decisions

- A good test drives the program at its own boundary and checks what it prints, never how it got there. The sim test loads the real E1M1 through the same loader the game uses, runs a scripted command list through the same step the game uses, and prints position and angle in map units. Expected values are pinned after a hand check against Doom's known constants (start at 1056, -3616 facing east; walk thrust 25 per tic; friction 0.90625).
- Prior art is the WAD directory test: a main whose output must match its trailing `#|` lines, run under BENDOOM_IWAD, on both lanes.
- Laws are the other check: universal ones over all command lists and all positions in LAWS.bend, closed sanity ones evaluated by the checker, all filled in PROOF.bend so the flake check gates them.
- The fixed-point and lump modules get no tests of their own beyond closed laws; they are exercised through the sim test.
- A measurement, not a test: one representative column loop written in emulated fixed point and in F32, timed as native binaries, reported as a number before milestone 3 starts.

## Out of Scope

Rendering walls, floors or the sky; doors, lifts, switches and the exit; things other than the player start; monsters, weapons, damage and the status bar; sound and music; demo recording or playback; saving; the -iwad flag and any command-line arguments; aspect-ratio correction of the frame; Hellbent.

## Further Notes

- Every complete Doom rewrite that reports on it names the renderer's shared state and 32-bit fixed-point semantics as the two hardest parts. This milestone takes on the second one deliberately and early, in the sim, where laws can hold it.
- Bend constraints that shape all the code, learned in milestone 1: helpers before callers; no tuple pattern on a call result; the shrinking argument first in a recursive call; no mutual recursion; lists need the reusable quantity to be read twice; rewrites replace the right side of an equation by the left.
- The wall law is only as strong as the "free" predicate. The second law is what gives it teeth, and its proof is the risky part of this milestone.
- Open question for the maintainer: the single test seam (scripted tic commands through the sim over the real E1M1, printing position and angle) plus laws. Confirm or change before issues are cut.
