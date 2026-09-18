# 09: The exit ends the level, Space restarts

**What to build:** Special 11. The exit switch swaps its texture and marks the level ended at that tic; from then on the tic is the identity. The game holds the last frame, prints the level time in minutes and seconds to stdout once, and on Space or Enter builds a fresh state from the map as loaded and plays E1M1 again. Esc and Close still quit. The intermission is milestone 6's.

**Blocked by:** 06 (Switches)

**Status:** resolved

- [x] A closed law on a literal level with an exit switch pins the ended flag, the tic it was set on, and that a further tic of any command changes nothing
- [x] The frame after the exit shows the pressed switch
- [x] The time printed is the clock over 35, as vanilla's tally shows it
- [x] After a restart the state equals the state the game started with: a door opened before the exit is shut, a fired once-only line has its special back
- [x] Checked in the window through the screenshot tool with a binary built to start beside an exit switch, or by a scripted run; how it was checked is recorded in the comments
- [x] Both lanes pass; the flake check stays green

## Comments

Read out of Freedoom in nushell and worked out from linuxdoom-1.10 before the Bend code answered:

- The exit is line 407, from (-400, 1280) to (-400, 1312), one-sided, special 11, tag 0, its front side 615 (sector 67, middle SW1GRAY). It runs north, so its front is east of it. Sector 67 is the switch's niche, 16 deep, floor -120 and ceiling -56; line 405 at x -384 (two-sided, no special) opens it onto the exit room, sector 66, floor -128 and ceiling 8. The opening of 405 is from -120 to -56, 64 units, more than nothing, so a use trace goes through it.
- A player at (-352, 1296) facing 180 stands in sector 66 clear of every wall (the box reaches x -368). The 64-unit trace west meets line 405 at 32 units and line 407 at 48, from 407's front. So the script `20,0,0,0,0 1,0,0,0,1 10,25,0,0,1` from `-352 1296 180` leaves the level live with the clock at 20 after its first run, ended with the clock at 21 after the use (`P_UseSpecialLine`'s case 11 is `P_ChangeSwitchTexture(line, 0)` then `G_ExitLevel`, which only sets `gameaction`, so `P_Ticker` finishes the tic and counts it), line 407's special 0, and the third run changes nothing: clock 21, the player where the use left it.
- The time is `wminfo.plyr[].stime`, which `G_DoCompleted` reads from `leveltime` at the head of the next `G_Ticker`, so it is the clock after the exit's tic, and `WI_drawTime` shows it over `TICRATE` as seconds modulo 60 and minutes. A clock of 21 is 0:00; 4321 is 123 seconds, 2:03; 2099 is 0:59 and 2100 is 1:00.
- The laws' literal level is `Closed.doors()` with line 0's special 11 in place of 1, side 0's middle texture numbered 1, and texture 1's partner 2 (and 2's 1). The west room's player, 32 units from the line and facing it, idles two tics and uses on the third: ended is false with the clock at 2, then true with the clock at 3, line 0's special is 0, side 0's middle is 2, and a tic of any command after that answers the same state.

Done. The sim answered the hand computation on Freedoom: live with the clock at 20, ended with the clock at 21 on the tic of the use, line 407's special 0, and ten tics of walking with use held leave the clock at 21 and the player at -352, 1296. The shareware map answers the same from `2944 -4768 180` (its exit, line 330, runs north from (2912, -4800) with its front to the east, so the hand expectation is the same 21), and its frame changes with the press. The time printed for the hand clocks is 0:00, 0:59, 1:00 and 2:03. The closed law `exit_ends` checks with the numbers above, by `{==}`; with the special's expected 0 turned to 11 it fails, so it is read. The proof check still takes 40 seconds.

What was built:

- Special 11 is `State.end(Sim.once(i, Sim.switch(i, s)))` in `Sim.use.special`: vanilla's swap, the cleared special, then the flag. The thinkers and the clock of that tic run on it as on any state, and `Sim.tic.kept` brings the flag back, so nothing else in the tic changed.
- A level now starts with use counted as down (`State.at`), which is `G_PlayerReborn`'s `usedown = true`, "don't do anything immediately". It is what keeps the Space that restarts the level from also being a use on the new level's first tic, and it is what vanilla does with a demo whose first tic presses use. No script of the tests or the tickets pressed use on a first tic, so every line and hash stayed; the sim test now pins it (use on tic 1 beside the exit does nothing).
- In `src/game.bend` the frame's tics run from `Game.from`, which is a fresh `State.start(level)` of the map as loaded when the level has ended and Space or Enter was pressed, and the state otherwise. `Game.tally` prints `Game.time` on the frame whose tics took the state from live to ended, which is once by construction, with no flag for it. The held frame needs no code: an ended state's tic is the identity and the view draws the state. `Game.step` and `Game.advance` moved into IO for the print; `Game.frame` is the loop's frame with the clock reading passed in, which is the seam the new test drives.
- It differs from the brief in one place. The restart key is not read in `Game.event` as a press event. The first build did that, and in the scripted run below Space held at the exit switch past the keyboard's repeat delay restarted the level under the player. The runtime leaves X's auto-repeat on, so a held key arrives as a release and a press back to back, and the Mac runtime sends repeated presses with no release. So `Game.key` folds Space and Enter into one held flag, `again`, and a press is that flag up before the frame's events and down after them. Both kinds of repeat then read as still held. The price is one Bool in `Game`. A tap shorter than a frame is missed, as it already is for every gameplay key.
- The time is `M:SS`. `WI_drawTime` draws two digits of minutes once there are any and "sucks" past an hour; a line of text keeps the plain form.

Tests:

- `tests/sim.bend`: the exit runs above, after the blue door, which now closes its block with `-` so that `end` stays last.
- `tests/game.bend` is new, and the first test of the game's frame: key events and a clock reading in, the state and the printed line out, no window. A script opens the exit room's door from inside (sector 64, line 389; hand: floor -128, sector 68's ceiling -56, so its top is -60, there 34 tics after the use) and walks to the switch; the game is handed that state at tic 50. A frame with Space pressed ends the level on its first tic and prints `Time 0:01` (51 tics); a frame with X's repeat of Space (release, press) restarts nothing, nor does the release; Enter restarts, and with no time gone the line is the start's line: tic 0, the player at the start, no thinker, sector 64 shut at -128, line 407's special 11 again, the side's texture the one loaded. Esc quits. With `Game.from` made to build from the state's level instead of the loaded map, the test fails on that line (door at -60, special 0), which is the mistake it is there for. The positions are regression pins.
- `tests/render.bend` pins the frame after the exit (hash 847822191, which nushell worked out from the frame dump before the test answered).

Oracle. Vanilla leaves the level on the tic after the exit, so it never stands in the held frame. The comparison goes through a copy of Freedoom whose side 615 names SW2GRAY, eight bytes patched in nushell and given to the tool as `--wad`. From `-352 1296 180`:

| what | differing |
| --- | --- |
| the loaded map after `21,0,0,0,0`, the switch unpressed | 0 |
| the patched map after `21,0,0,0,0`, vanilla drawing SW2GRAY there | 0 |
| our dump of the loaded map after `20,0,0,0,0 1,0,0,0,1 10,0,0,0,0` against our dump of the patched map after `21,0,0,0,0` | identical files |

The clock stops at 21 on both sides of the last row, so the held frame is vanilla's picture of that wall with the pressed switch, pixel for pixel.

Checked in the window by a scripted run, headless. The game ran a copy of Freedoom whose player 1 start is `-352 1296 180`, the thing patched in nushell, on an Xvfb of its own with `-fbdir`. xdotool sent the keys through XTEST, so the server repeats them, and the framebuffer file was copied after each step and the copies hashed. Space: `Time 0:02` on stdout, once, and the switch shows its pressed face. Up held for 0.7 s: the same frame, byte for byte. Enter: the start's frame, byte for byte. Space held 2.5 s: the time of the second exit, the pressed frame still there at the end of the hold (the first build had restarted by then), then a tap restarts and prints nothing. Esc: the process is gone. No window opened on the desktop.
