# Milestone 4: doors, the lift, switches, the exit, and the lights

Status: ready-for-agent

## Problem Statement

Bendoom's E1M1 is a still life. The player walks up to the first door and stops there for good, because nothing in the level moves: doors stay shut, the lift stays up, switches ignore the use key, and the exit switch ends nothing. The rooms the player does reach look frozen too. The lights that blink in vanilla hold one level, the water and the computer screens show one frame, and the shareware map's scrolling walls stand still. A port's player expects to open the door, ride the lift, flip the switch and leave the level, and expects each of those to take the tics vanilla gives it.

## Solution

The level comes alive as vanilla's does. Space is the use key. Doors open, wait and close at vanilla's speeds, the lift lowers when walked onto or switched, floors lower when their trigger is crossed or pressed, switches change their texture, and the exit switch ends the level. Sector lights blink, strobe and glow, animated flats and textures cycle, and the scrolling walls scroll. With no intermission to draw until milestone 6, the exit holds the last frame, prints the level time, and Space or Enter starts E1M1 again.

The reference stays the linuxdoom-1.10 source and Chocolate Doom, and this milestone makes the comparison tic-exact. The oracle tool writes a command script as a vanilla demo that ends in a pause, Chocolate Doom plays it, and the frozen tic's screenshot is diffed against our frame at the same tic. A door halfway open is then a frame vanilla can confirm or refute.

## User Stories

1. As a player, I want Space to use what I face, so that doors and switches answer as they do in Doom.
2. As a player, I want use to reach 64 units along my facing and act on the first special line it meets, so that I open a door from where vanilla lets me.
3. As a player, I want a wall or a closed opening between me and a switch to stop the use, so that I cannot press through walls.
4. As a player, I want use to act once per press, so that holding Space does not open and close a door every tic.
5. As a player, I want only the front of a line to answer use, so that switches work from the side the map author drew them on.
6. As a player, I want a manual door to rise at 2 units a tic to 4 under its lowest neighbouring ceiling, wait 150 tics and close, so that doors move as Doom's.
7. As a player, I want a second use on a manual door to send a closing door back up and an open or opening one down, so that I can hurry or hold a door as in Doom.
8. As a player, I want a door that closes on me to go back up, so that a door never traps or clips me.
9. As a player, I want the blazing door to move at four times the speed, so that Freedoom's fast door is fast.
10. As a player, I want doors opened by a walked-over line to open and stay open, once, so that the rooms Freedoom's map reveals stay revealed.
11. As a player, I want the blue key doors to refuse me, so that the key Freedoom's map asks for still gates its optional area until milestone 5 brings keys.
12. As a player, I want the lift to lower at 4 units a tic to its lowest neighbouring floor, wait 105 tics and rise, so that I can ride it as in Doom.
13. As a player, I want the lift to answer both its walk-over lines and its switches, every time, so that it can be called from above and below.
14. As a player, I want a lift that rises into me to go back down, so that I am never crushed by it.
15. As a player, I want to stay on the floor of a lift as it moves, my eye moving with it and no dip, so that riding feels like Doom.
16. As a player, I want floors that a trigger lowers to move at vanilla's speed to vanilla's height, so that the shareware map's lowering floor and Freedoom's switched floors end where they should.
17. As a player, I want a one-shot trigger to work once, so that the map's sequence cannot be replayed.
18. As a player, I want a switch to show its pressed texture when used, so that I can see it took.
19. As a player, I want a repeatable switch to pop back after 35 tics, so that it reads as ready again.
20. As a player, I want the exit switch to end the level, so that E1M1 can be finished.
21. As a player, I want the finished level to hold its last frame and tell me the time I took, so that finishing registers before an intermission exists.
22. As a player, I want Space or Enter after the exit to start E1M1 again from its loaded state, so that I can play again without relaunching.
23. As a player, I want the blinking, strobing and glowing sectors of E1M1 lit as vanilla lights them tic by tic, so that the level's mood is Doom's.
24. As a player, I want animated flats and textures to cycle every 8 tics, so that the water and the screens move.
25. As a player, I want the shareware map's scrolling walls to scroll one unit a tic, so that they look as they do in Doom.
26. As a player, I want moving floors and ceilings drawn at their current heights with their textures pegged as vanilla pegs them, so that a rising door looks like Doom's.
27. As a player, I want both the shareware E1M1 and Freedoom's first map completable from start to exit with no key, so that no proprietary data is needed to finish the game as it stands.
28. As a player, I want the frame rate to stay at 35 or more with every mover and light running, so that the living level plays as the still one did.
29. As a developer, I want the sim to take a tic command (forward, side, turn, use) and not the held keys, so that a script is the same thing as a vanilla demo.
30. As a developer, I want the turn keys' held count out of the player and beside the held keys in the game's input state, so that the sim's state holds only what vanilla's playsim holds.
31. As a developer, I want everything that changes per tic in one state value the tic maps to the next, so that replay stays a pure fold and a frame at any tic is reproducible.
32. As a developer, I want the changing words of the map (sector floor, ceiling and light, a line's special, a side's textures) written where the readers already look, so that the position check and the renderer keep their accessors and no overlay lookup exists.
33. As a developer, I want the map as loaded kept apart from the state, so that restart is a rebuild and not a reload of the WAD.
34. As a developer, I want the tic to run in vanilla's order (the player's think with its use, the player's movement, the light thinkers, the movers in the order they were started, then animations, scrolls and switch timers, then the clock), so that a door used this tic moves this tic, as vanilla's does.
35. As a developer, I want walked-over specials fired from the move that crossed them, for each special line whose side the player changed, so that triggers fire on the tic vanilla fires them.
36. As a developer, I want a moving plane to re-clip the player through the same position check the move uses, and to honour the moving sector's block box as vanilla does, so that a blocked mover is blocked when vanilla's is.
37. As a developer, I want vanilla's random table and its index in the state, so that the blinking light runs vanilla's sequence.
38. As a developer, I want the loader to compose the partner of every switch texture the map names and every frame of every animation the map touches, so that a swap never names a missing graphic.
39. As a developer, I want only the specials that one of the two E1M1s carries implemented, so that each branch in the code has a map that needs it.
40. As a developer, I want the oracle tool to take a command script, write it as a vanilla demo ending in a pause, and diff the frozen tic against our frame at that tic, so that movers and the walk are checked against vanilla to the tic.
41. As a developer, I want the oracle's map to keep its line and sector specials, so that the frames it compares are the real map's.
42. As a developer, I want the oracle's eight-shot tolerance for animations deleted, so that a compared frame is one shot and every pixel must match.
43. As a developer, I want the frame dump to take the same script the oracle plays, so that both sides run the same commands.
44. As a developer, I want the sim test to print the mover's heights beside the player at chosen tics of scripted runs, so that doors and the lift are checked at the program's boundary on both lanes.
45. As a developer, I want a scripted run that walks Freedoom's E1M1 from the start to the exit switch in the sim test, so that "completable" is a test and not a claim.
46. As a developer, I want the render test to pin frames with a door half open, a switch pressed and a light at its dark level, so that the renderer's view of the changing state is covered on both lanes.
47. As a developer, I want the differing-pixel count recorded for every scripted oracle position, so that the milestone's fidelity is a number in the ticket.
48. As a proof author, I want the wall law to keep holding with the level in the state, so that no mover can put the player in a wall.
49. As a proof author, I want a law that a tic never changes the geometry the wall law reads, so that the wall law's proof needs no fact about movers.
50. As a proof author, I want closed laws pinning a door's timeline on a literal two-room level (the height after the first tic, the tic it reaches the top, the tic it starts down, the tic it is shut), so that the checker gates vanilla's door arithmetic.
51. As a proof author, I want closed laws pinning the lift's timeline and the two floor movers' destinations the same way, so that every mover's numbers are vanilla's.
52. As a proof author, I want a law that use held across tics fires on the first alone, so that the press edge is proven.
53. As a proof author, I want a law that a used one-shot line has no special afterwards, so that once means once.
54. As a proof author, I want closed laws pinning the first entries of the random table and the blink's first counts, so that the light sequence is vanilla's.
55. As a proof author, I want the replay law (two scripts in turn are their concatenation) to keep holding over commands and the wider state, so that scripted tests compose.
56. As a packager, I want the flake to build with no new inputs and the new tests in the flake check against Freedoom, so that the build graph stays five nodes and proves the movers move.
57. As a reader of the README, I want milestone 4's line to name the lights, animations and scrolling walls, so that the ladder says what was built.

## Implementation Decisions

- The specials in scope are the ones the two E1M1s carry, read from the WADs. Lines: 1 (manual door), 117 (manual blazing door), 26 (manual blue key door), 2 (walk once, door opens and stays), 62 and 88 (switch and walk, repeatable, lift lowers, waits, rises), 23 (switch once, floor lowers to the lowest neighbouring floor), 36 (walk once, floor lowers fast to 8 above the highest neighbouring floor), 11 (switch, exit), 48 (wall scrolls left). Sectors: 1 (random blink), 8 (glow), 12 (slow strobe, in sync). Sector specials 7 and 9 stay inert until damage and the tally exist. Any other special does nothing, as an unknown special does in vanilla.
- The sim takes a tic command of forward, side, turn and a use button. The keys module still builds it from the held keys with vanilla's tables, and the six-tic slow turn's held count moves from the player to the game's input state, where vanilla's G_BuildTiccmd keeps it. Space is use. The sim's replay folds a list of commands.
- The state the tic maps is one value: the player, the level with its changing words, the side texture numbers, the active thinkers, the random index, the clock, and whether the level has ended. The changing words are a sector's floor, ceiling and light, a line's special, and a side's three texture numbers. They are written by a path-copying write on the copyable tree, in the trees the readers already use, so the position check and the renderer read a moved floor with the accessor they have. A line's special and tag live in a tree of their own, apart from the vertices, flags and sides the wall law reads, so that the tic can be shown never to write the geometry.
- The map as loaded is kept beside the state. Restart builds a fresh state from it.
- The tic follows P_Ticker's order. The player thinks (move, eye, then use on the press edge). The player's XY and Z movement run. Light thinkers run in sector order, as P_SpawnSpecials made them. Movers run in the order they were started, so a door used this tic moves this tic. Then the switch timers count down, and the clock advances. When the level has ended the tic is the identity.
- Use is P_UseLines: a trace of 64 units along the facing, its hits sorted by distance. A line without a special lets the trace continue when its opening is more than zero and stops it otherwise. The first line with a special ends the trace whatever the special, and acts only when the player is on its front side. The trace reuses the slide's line gathering and intercept.
- Walk-over triggers are P_TryMove's: after a move is taken, each special line the player's box crossed is tested, newest first, and fires when the player's side of it changed. A once-only line's special is cleared when it fires.
- Doors are T_VerticalDoor with vanilla's numbers: speed 2 a tic (8 blazing), top at the lowest neighbouring ceiling minus 4, wait 150 tics, then down to the floor. A manual use on a sector with a running door reverses it (closing goes up, otherwise down). An open-and-stay door stops at the top. The blue key door refuses, since the player holds no keys until milestone 5, and the refusal is silent until messages and sound exist.
- The lift is T_PlatRaise's down-wait-up-stay: speed 4, low at the lowest neighbouring floor no higher than its own, wait 105 tics, back to the height it started at, then its thinker ends. A tagged trigger starts every tagged sector that has no thinker.
- Floors are T_MoveFloor: speed 1 to the lowest neighbouring floor for special 23, speed 4 to the highest neighbouring floor for special 36, plus 8 when that is not its own height.
- All planes move through one T_MovePlane: a step that would pass the destination lands on it, and after each step the player is re-clipped. The re-clip is P_ThingHeightClip through the existing position check: floor and ceiling under the player are recomputed, a player on the floor stays on it, a player whose head is in the ceiling is lowered, and the answer is whether the player still fits. It runs when the player is inside the moving sector's block box, which the loader computes as P_GroupLines does, from the sector's lines widened by 32 units. A step the player does not fit is undone and reported crushed. A crushed normal door goes back up, a crushed rising lift goes back down and waits. No mover in scope damages.
- Switches are P_ChangeSwitchTexture with the shareware switch list. The front side's top, middle or bottom texture, whichever is a switch, swaps to its partner. A once-only switch clears its line's special. A repeatable one starts a 35-tic timer that swaps it back. The loader composes the partner of every switch texture the map's sides name.
- The exit switch swaps its texture and marks the level ended at that tic. The game then holds the last frame, prints the level time in minutes and seconds to stdout once, and Space or Enter restarts. Esc and Close still quit.
- Lights are p_lights.c: the random blink (a bright count of 1 or 65 tics, since vanilla masks the random byte with 64, and a dark count of 1 to 8, between the sector's light and the lowest neighbouring light), the in-sync slow strobe (35 dark, 5 bright, the dark level 0 when no neighbour is darker), and the glow (8 a tic between the sector's light and the lowest neighbouring light). The random table is vanilla's 256 entries, a chunked table like the others, and the index starts at 0 with the level.
- Animation and scrolling are functions of the clock, not state. The renderer translates a flat or texture number through vanilla's animation list at 8 tics a frame, with the phase P_UpdateSpecials would have set on the last tic run. An animation exists when the WAD holds its first and last name, and its frames are the lumps or textures between them in WAD order, as vanilla counts them. The loader composes every frame of every animation that holds a name the map uses. A side on a line with special 48 draws with its offset advanced by one unit per tic run.
- The renderer reads sector heights and light, side textures and the clock from the state. It stays a pure function, and its frames at tic 0 with no command are the frames it draws today.
- The frame loop still runs the tics the clock owes. It builds each tic's command from the held keys and the held count.
- The oracle tool gains one argument, a command script in demo units (a run count, then forward, side, the 8-bit turn and use), and loses its eight-shot loop. It keeps the player-start PWAD but leaves the line and sector specials in. It writes the script as a version 109 demo with no monsters whose last command presses pause, followed by idle commands, runs Chocolate Doom with the demo in real time, shoots once inside the paused tail, and masks the status bar, the pause graphic and the pistol with its bob's reach. A rest position is the script that idles until the pistol is up. The frame dump reads the same position and script and replays it through the sim before it renders.
- README's milestone 4 line is rewritten to name what was built.

## Testing Decisions

- A good test here checks what the program does at its boundary: given a WAD, a start and a command script, which state and which frame come out. It does not name a thinker's fields or a helper's result. Every test has one seam, the replay of a script, and what is printed after it.
- Expected values come from outside the code. Mover heights and tics are computed by hand from vanilla's constants and the sector heights read out of the WAD in nushell, written into the ticket before the Bend code answers. Values with no outside source are regression pins and the ticket says so.
- The sim test grows scripted runs on Freedoom: the first door used and followed tic by tic through open, wait and close, a second use that reverses it, the player standing under a closing door, the lift ridden down and up, a switched floor, a repeatable switch's timer, the blue door's refusal, and the walk from the start to the exit switch with the tic it ended on. The existing walks keep their lines, since the change from keys to commands must not move them.
- The render test gains frames at tics of those runs: a door half open, a pressed switch, a blinking sector at its dark level, an animated flat on a later frame. Hash and sampled pixels, as the existing frames.
- The oracle is Chocolate Doom playing our script as a demo. Every rest position of the render test must still report zero differing pixels, now from a single shot with animations and lights running. Each scripted frame of the render test is compared too, the count recorded in the ticket, target zero. The completion script is checked at its end: paused one tic before the exit Chocolate Doom shows the level, and one tic after it has left it. The oracle stays a tool outside the flake check, headless on Xvfb.
- Laws: the wall law, the tic's freedom law and the replay law are restated over commands and the wider state and must keep holding. New universal laws: a tic never writes the geometry trees, use held fires once, a fired one-shot line has no special. New closed laws on a literal level of two rooms and a door sector between them: the door's timeline, the lift's, the two floors' destinations, the re-clip keeping a standing player on a moving floor, the first random entries and the blink's first counts. All filled in the proof file so the flake check gates them.
- Prior art: the sim test's tagged runs, the render test's hashed frames, the oracle's PWAD writer and masks, the closed laws on the one-room literal level, and the chunked tables.
- The frame rate is measured in the window on the dev machine with a door moving and the lights running, and recorded in the ticket with the machine named. The bar is milestone 3's 35.
- The shareware map is finished once by hand through the screenshot tool or the window, and the ticket records it. Its unfree WAD stays out of the flake check.

## Out of Scope

Things, sprites, the weapon and pickups, so no keys and no opening blue door. Damaging floors and the secret count. Crushers, stairs, teleporters, raising floors, perpetual lifts and every special neither E1M1 carries. Door, lift and switch sounds. The "you need a blue key" message. The intermission, the screen melt, a second map. Playing or recording demos inside the game. Save games, menus, the automap, Hellbent.

## Further Notes

- Trade-offs taken, each open to the maintainer's call. Only the specials the two E1M1s carry are written, so another map would find its movers dead, and the price of generality would be a branch per special with no map to check it. The blue key doors refuse until milestone 5, which shuts 12 of Freedoom's 182 sectors, and a reachability pass over the map's two-sided lines says the exit does not need them. The exit holds and restarts where vanilla tallies and loads E1M2. The light, animation and scroll work makes this the largest milestone so far, taken because the shape of the changing state should be settled with every consumer known and because the oracle can then compare the real map. Demo turns are 8 bits, so oracle scripts cannot express the live game's slow turn of 320, and a walked script turns in steps of 256. The pistol's bob widens the oracle's mask on walking frames, so fewer pixels are compared there than at rest.
- The risk is the demo oracle. It rests on four things Chocolate Doom should do and nobody here has tried: play a demo file against a PWAD, honour a pause command during playback, keep the paused tail alive in real time, and take its screenshot while paused. The first ticket proves it with an idle script at the start position, which must report the zero that position reports today. If the pause does not hold, the fallback is the settled-state comparison, a use key sent by xdotool and a shot once the mover has stopped, with speeds and waits left to the closed laws.
- The second risk is the wall law's proof once the level is part of what the tic returns. Keeping the changing words out of the trees the law reads is what should keep the proof a matter of showing those trees pass through untouched.
- A scripted route to the exit is written as runs against the sim's printed positions, the way the earlier walks were found. Nothing records play.
- Vanilla's use has a known oddity that is kept: any special line, even a walk-over one, stops the use trace.
- The Bend constraints that shape all the code are in `docs/bend.md`.
