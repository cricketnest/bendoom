# Milestone 3: walls, floors, ceilings and the sky

Status: ready-for-agent

## Problem Statement

Bendoom's window shows a top-down line drawing of E1M1. A player of a Doom port expects to see Doom: textured walls in perspective, lit by distance and by the sector's light, floors and ceilings in their flats, the sky through open ceilings, all at Doom's 320 by 200 with its pixel look, and the eye bobbing as they walk. Close is not enough: it is a port, so a frame should be the frame vanilla Doom draws, pixel for pixel, wherever the two can be compared.

## Solution

Replace the top-down view with vanilla Doom's software renderer, in the same 16.16 fixed point as the sim so that each frame is bit for bit vanilla's: the BSP walked front to back, wall ranges clipped against the solid columns already drawn, columns textured from the WAD's patches and lit through the colormap, floors and ceilings gathered as visplanes and drawn as spans, the sky as a texture indexed by view angle, and two-sided middle textures drawn last through the recorded wall segments. The frame is palette indices; the palette is applied when the frame is folded into the window, at four pixels a cell, corrected to the 4:3 aspect of the monitor Doom was drawn for. The player gains an eye: height above the floor, walking bob, the dip after a step up and the fall off a ledge, as vanilla computes them. The reference for every pixel is the 1997 linuxdoom-1.10 source and Chocolate Doom; the proof of fidelity is a diff against a Chocolate Doom screenshot at the same position.

## User Stories

1. As a player, I want to see E1M1 from the player's eye in perspective, so that I am playing Doom, not reading a map.
2. As a player, I want one-sided walls drawn with their textures, so that rooms look as they do in Doom.
3. As a player, I want the upper and lower textures of two-sided lines drawn where the ceilings and floors step, so that stairs, ledges and lowered ceilings look right.
4. As a player, I want the middle textures of two-sided lines drawn with their transparent parts see-through, so that grates and bars look as they do in Doom.
5. As a player, I want textures pegged as the map says, so that textures do not slide when the map's flags anchor them to the floor or the top.
6. As a player, I want the sidedef offsets applied, so that textures line up across walls as the map author intended.
7. As a player, I want floors and ceilings drawn in their flats, so that the ground and the roof are textured.
8. As a player, I want the sky drawn through ceilings marked as sky, so that outdoor areas open onto Doom's sky.
9. As a player, I want the sky to pan as I turn, at Doom's rate, so that it reads as a distant backdrop.
10. As a player, I want walls to dim with distance, so that depth reads as it does in Doom.
11. As a player, I want floors and ceilings to dim with distance on their own scale, so that they match vanilla's look.
12. As a player, I want each sector's light level to set how bright it is, so that dark corridors are dark.
13. As a player, I want walls facing north or south to draw a little brighter than walls facing east or west, so that corners read as in Doom's fake contrast.
14. As a player, I want the frame at Doom's 320 by 200 shown four pixels a cell, so that the pixel look is Doom's.
15. As a player, I want the frame stretched to 4:3, so that it has the proportions of Doom on the monitor it was drawn for, as Chocolate Doom shows it.
16. As a player, I want the frame drawn with the WAD's own palette, so that the colours are Doom's.
17. As a player, I want the view to take the top 168 rows and the bottom 32 to stay black for now, so that the view is the size it will keep when the status bar arrives.
18. As a player, I want my eye 41 units above the floor, so that walls are the height they are in Doom.
19. As a player, I want my view to bob as I walk and run, so that movement feels like Doom.
20. As a player, I want my view to dip and recover when I step up, so that stairs feel like Doom's.
21. As a player, I want to fall when I walk off a ledge, at Doom's gravity, so that drops look like Doom's and not a snap.
22. As a player, I want my view to dip when I land from a fall, so that landing feels like Doom's.
23. As a player, I want the frame to show the latest tic's state with no interpolation, so that the motion is vanilla's.
24. As a player, I want at least 35 frames a second on a laptop, so that the game plays as smoothly as the original.
25. As a player, I want no hall of mirrors or garbage where E1M1 is well-formed, so that every pixel of the view is drawn each frame.
26. As a player, I want the shareware E1M1 and Freedoom's first map both to render, so that no proprietary data is needed.
27. As a player, I want Esc and Close to keep quitting, so that I can leave at any time.
28. As a developer, I want the renderer to be a pure function of the level, the graphics and the eye, so that a frame can be rendered in a test without a window.
29. As a developer, I want the renderer to follow vanilla's stages and formulas in the same fixed point, so that its frames are vanilla's frames and can be diffed against them.
30. As a developer, I want the level to carry the segs, subsectors, node bounding boxes, sector flats and light levels, and sidedef textures and offsets, so that the renderer reads what vanilla reads.
31. As a developer, I want the palette, the colormaps, the patch names, the texture definitions, the patches and the flats loaded from the WAD, so that no graphic is baked into the program.
32. As a developer, I want only the textures and flats E1M1 names composed at load, so that loading Freedoom's 800 textures does not stall the start.
33. As a developer, I want the frame to be palette indices until it is shown, so that frames compare with vanilla's screenshots directly.
34. As a developer, I want a test that renders frames at the start and at scripted positions and prints a hash and sampled pixels, so that rendering is checked at the program's boundary on both lanes.
35. As a developer, I want a tool that produces vanilla's frame at a chosen position from Chocolate Doom and diffs it against ours, so that fidelity is measured, not claimed.
36. As a developer, I want the number of differing pixels recorded for each compared position, so that the fidelity of the milestone is a number in the ticket.
37. As a developer, I want the renderer to have no static limits on visplanes, drawsegs, solid segments or openings, so that no vanilla overflow crash is reproduced.
38. As a developer, I want the frame rate measured and recorded on the dev machine, so that the 35 frames a second story is a number.
39. As a developer, I want the top-down view deleted, so that no throwaway code remains.
40. As a proof author, I want a law that the solid-column list stays sorted and disjoint after any wall range is clipped into it, so that vanilla's most error-prone loop is proven.
41. As a proof author, I want a law that drawing a column changes no pixel outside its top and bottom rows, so that nearer walls are never overdrawn.
42. As a proof author, I want closed laws pinning the view tables at known entries, so that the projection is vanilla's.
43. As a proof author, I want closed laws pinning the wall scale, the texture column, the light index cap and the sky column at known inputs, so that the per-column arithmetic is vanilla's.
44. As a proof author, I want the sim's laws to keep holding with the player's new fields, so that the wall law survives the eye.
45. As a proof author, I want a law that standing still on the floor leaves the eye at 41 above it, so that the resting view is pinned.
46. As a packager, I want the flake to keep building with no new inputs, so that the build graph stays five nodes.
47. As a packager, I want the render test in the flake check against Freedoom, so that the build proves the renderer draws.
48. As a developer, I want the Python reference sim deleted, its hand-checked numbers kept as closed laws, and the table generator rewritten in nushell, so that the repo holds no Python and its scripts share one language.

## Implementation Decisions

- The renderer is vanilla's, stage for stage, in the sim's 16.16 fixed point, as ticket 15 of milestone 2 decided: the frame is set up from the eye (position, eye height, angle, with sine and cosine from the fine table), the BSP is walked front to back from the root, each node's bounding box is tested against the solid columns before descent, each subsector finds or splits its floor and ceiling visplanes and adds its segs, each seg is clipped by angle to the view and then against the solid-column list (solid segs and pass-through segs by their own rules), and each surviving range is stored with its scale from the global angle, its scale step, its textures chosen by pegging and side, its offset from the seg's distance, its light with fake contrast, and its silhouette. The seg loop then walks the range's columns, clips each by the ceiling and floor clip arrays, marks the visplanes, and draws the wall columns. After the walk, planes are drawn: the sky by columns of the sky texture indexed by the view angle at Doom's sky shift, flats by spans with the distance, step and light from vanilla's plane tables. Last, the masked pass walks the stored wall ranges back to front and draws two-sided middle textures column by column through their posts, clipped by the range's sprite clips.
- Every formula keeps vanilla's precision: the angle of a point through the tangent table, the scale from the global angle with its overflow guard and clamps, the reciprocal scale by the 32-bit division, the texture column from the offset minus the tangent times the distance, the column texel by the fraction's top bits masked to 127, the flat texel by the 64 by 64 wrap, the light index by the scale shift capped at the table's end, and the plane light by the distance shift capped likewise. The view tables (angle to column, column to angle, scaled light, plane light, row slope, distance scale) are computed at load with vanilla's formulas at view width 320, height 168, detail shift 0.
- The frame is a flat array of palette indices, 320 by 200, of which the top 168 rows are the view and the bottom 32 stay 0 until milestone 6 draws the status bar. The array is folded into the window's image quadtree at four pixels a cell; the fold reads the palette so the image is RGB. The window is 1280 by 960 and a cell row maps to the frame row at five sixths of it, so the 200 rows fill 240 cell rows: nearest-neighbour 4:3 correction, as Chocolate Doom's default.
- The graphics loaded from the WAD: the first palette, the colormaps, the patch names, the texture definitions from both texture lumps when the second exists, and the flats between the flat markers. Only the textures named by E1M1's sidedefs plus the sky texture, and the flats named by its sectors, are composed into indexed structures; every other name stays a directory entry. A single-patch texture reads its patch's columns as posts, so masked middle textures keep their transparency; a multi-patch texture is composed by pasting its patches as vanilla does. A texture or flat name the WAD lacks fails the load as vanilla fails it. Names are matched as vanilla matches them: eight characters, case-insensitive; a dash is no texture; the sky flat name marks a sky ceiling.
- The level record grows what the renderer reads: per seg its ends, its lump angle, its offset, its linedef and side; per subsector its seg count and first seg; per node its bounding boxes; per sector its floor and ceiling flats and light level; per sidedef its offsets and three textures. The lump's angle and offset are used as read, not recomputed, so the frame is vanilla's.
- The player gains a height above the floor, a vertical momentum, a view height and its delta, as vanilla's player has. Each tic, after the XY move, the vertical move runs: gravity when above the floor, the clamp to the floor with the landing dip, and the step-up dip when the floor rises under the player. The eye is then computed as vanilla computes it: the bob from the squared momentum capped at the maximum, the view height ramping back to its rest, and the eye height from the floor bounded by the ceiling. The step-up rule of the XY move now measures from the player's height, not its floor, as vanilla does.
- Data structures that vanilla bounds statically (visplanes, drawsegs, solid segments, openings) are lists with no limit. Where vanilla would abort with a limit error, this renderer draws; E1M1 never reaches a limit, so no frame differs.
- The game draws a frame from the latest tic's state at the runtime's frame rate, without interpolation, as vanilla does at 35.
- The renderer must hold 35 frames a second on the dev machine. How the texture, flat, colormap and palette data are indexed (copyable trees or owned arrays threaded through the draw), and whether the frame is drawn in one pass or as independent column ranges that each compute vanilla's exact columns, is chosen by measurement against that number; the measurement and the choice are recorded in the ticket.
- The top-down view is deleted; only its fold survives, in the module that shows the frame.
- Every script in the repo is nushell, written as nushell is meant to be written: commands with typed parameters and a usage comment, structured data through pipelines rather than text scraped from command output, and the standard library over shelling out where one exists. The screenshot tool already does; the table generator and the oracle tool follow it, and the Python originals go.
- The laws: the solid-column list is sorted and disjoint after any clip (universal, by induction over the list); a column draw leaves every row outside its bounds unchanged (universal); the resting eye is 41 above the floor (universal over positions); closed laws on a literal one-sector level pin the vertical movement (double gravity on the first airborne tic and single after, the landing dip, the bob cap and the step-up dip); and closed sanity laws pin the view tables and the per-column arithmetic at inputs whose vanilla answers are known.

## Testing Decisions

- A good test drives the program at its own boundary and checks what it prints, never how it got there. The render test loads the real map through the game's loader and the graphics through the game's loader, renders through the same function the game draws with, and prints, per frame, a 32-bit hash of the view's palette indices and the indices at a few fixed pixels. Frames are rendered at the start, at hand-chosen positions on the map (a sky in view, a lit and a dark sector, a step and a lowered ceiling, a masked middle texture) with the eye at rest on the floor and angles on multiples of 45 degrees, and at positions reached by the sim's scripted walk, so that the eye's bob and fall are covered. Expected values are pinned to Freedoom.
- The oracle is Chocolate Doom. A nushell tool writes a PWAD whose E1M1 things are one player start at the chosen position and angle, runs Chocolate Doom from nixpkgs on it with no monsters, waits for the weapon to finish rising, takes its screenshot, reads the paletted image, masks the status bar rows and the pixels the resting pistol sprite covers, and diffs it against our frame at the same position as dumped by a program outside the tests directory that prints the frame as hex rows. The count of differing pixels per compared position is recorded in the ticket; the target is zero. Positions are limited to angles on multiples of 45 degrees and the eye at rest, since that is what a player start can express.
- The vertical movement has no oracle: a Bend rewrite of the reference sim would share its author and constraints. Its values are computed by hand from vanilla's formulas once, then pinned as closed laws on a literal level, so the checker gates them; the runtime test covers them only through the frames at scripted positions.
- Prior art: the sim test and the WAD directory test, each a main whose output must match its trailing expected lines, run under the WAD environment variable on both lanes; the fixed-point bench, a measurement outside the tests directory.
- Laws are the other check: universal ones in the laws file, closed sanity ones evaluated by the checker, all filled in the proof file so the flake check gates them. The sim's existing laws are updated for the player's new fields and must keep holding.
- The frame rate is a measurement, not a test: frames per second in the window on the dev machine, recorded in the ticket with the machine named.

## Out of Scope

Things, sprites and the weapon; the status bar; doors, lifts, switches and the exit; damage, palette flashes and the invulnerability colormap; sound and music; the screen melt, menus and the title; the automap; view-size changes, gamma and detail modes; demo playback; the -iwad flag; Hellbent.

## Further Notes

- Trade-offs taken, each open to the maintainer's call: fixed point over F32 costs five times per column but keeps every frame vanilla's (ticket 15 of milestone 2); the 4:3 stretch makes the window 1280 by 960, taller than the current 800; the 168-row view leaves a black band until milestone 6, so screenshots compare with Chocolate Doom's default view size from now on; the eye's height, bob, dip and fall pull vanilla's vertical movement into the sim now, before lifts need it in milestone 4, because the renderer is the first thing that shows the vertical axis; masked middle textures come now because Freedoom's first map has 75 sides with one, though sprites join that pass only in milestone 5; static limits are dropped, so a map that overflows vanilla renders here instead of crashing; Chocolate Doom frames exist only at eight angles with the eye at rest, so bob and fall are checked by regression values, not against vanilla.
- The frame rate is the milestone's risk. A pure renderer over copyable trees pays a tree walk per texel; the bench measured the fixed-point column loop at 42 ns a column, but texel, colormap and palette lookups come on top. The ticket that draws walls measures first and chooses the data layout and the pass structure from the number.
- The medusa effect (vanilla's garbage on a multi-patch masked middle texture) is not reproduced; Freedoom's maps are built vanilla-clean, so no frame differs.
- The Bend constraints that shape all the code are in `docs/bend.md`.
