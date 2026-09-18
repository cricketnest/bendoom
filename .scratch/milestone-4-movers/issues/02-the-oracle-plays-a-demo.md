# 02: The oracle plays a demo

**What to build:** The milestone's risk, taken first. The oracle tool gains one argument, a command script in demo units: runs of a count, then forward, side, the 8-bit turn and use. It writes the script as a version 109 demo with no monsters whose last command presses pause, followed by idle commands, and runs Chocolate Doom with the demo in real time on the player-start PWAD, headless as before. It shoots once inside the paused tail and masks the status bar, the pause graphic (its box read from the WAD's patch) and the pistol widened by its bob's reach. The frame dump reads the same position and script and replays it through the sim before it renders, so both sides run the same commands. A rest position is the script that idles. The eight-shot loop and its varying count are deleted, since a paused tic is one frame.

Until tickets 10 and 11 land, the PWAD still zeroes sector specials and line special 48, and keeps every other line special. Until ticket 11, the rest script idles to a tic where every animation shows its first frame (vanilla's phase is the tics run less one, over 8, so 97 tics covers cycles of three and four), since Bendoom draws only that frame.

This rests on four things nobody here has tried: Chocolate Doom playing a demo file against a PWAD, honouring a pause during playback, keeping the paused tail alive in real time, and taking its screenshot while paused. If the pause does not hold, stop and record what failed in the comments. The fallback in the spec's notes (a use key sent by xdotool and a shot once the mover has settled) is then the maintainer's call.

**Blocked by:** 01 (The sim takes commands)

**Status:** resolved

- [x] An idle script at the start position reports zero differing pixels from one shot
- [x] Every rest position of the render test reports zero from one shot; the counts are recorded in the comments
- [x] The render test's three walked frames (the stride, the airborne tic, the landing) are compared for the first time, their scripts given in demo units; each count is recorded, and any difference is a sim or renderer bug to fix or to explain in the comments
- [x] The demo's bytes are vanilla's: the 13-byte header, four bytes a tic, the 0x80 end; checked against linuxdoom's G_ReadDemoTiccmd, not against our own reader
- [x] The tool's header comment describes the demo, the pause and the masks, and no longer describes eight shots
- [x] No window opens and no focus moves on the desktop

## Comments

Done, and the risk is retired: Chocolate Doom 3.1.1 plays a demo file against the PWAD (`-file start.wad -playdemo script`, the demo beside it as `script.lmp`), honours the pause tic during playback, keeps reading the idle tail at 35 a second while the playsim stands still, and takes its F1 screenshot while paused. A shot counts only once every pixel of the WAD's `M_PAUSE` patch is in it where vanilla draws it (126, 4), so a shot from before the pause cannot be compared by mistake; the first shot has been the paused one in every run. A run takes about 9 seconds plus the script's length.

The demo's bytes, against linuxdoom's `G_DoPlayDemo` and `G_ReadDemoTiccmd`: the header is the version 109, skill, episode, map, deathmatch, respawn, fast, nomonsters, consoleplayer and four playeringame bytes, 13 in all (`6d 00 01 01 00 00 00 01 00 01 00 00 00`); a tic is forwardmove and sidemove as signed chars, the turn's high byte, and the buttons, where use is bit 1 and pause is `BT_SPECIAL | BTS_PAUSE`, 0x81; 0x80 ends it. The pause tic runs no playsim tic (`P_Ticker` returns at once when paused), so the frame is the one after the script's last command.

The masks are the patches' own pixels, read from the WAD by one reader: `M_PAUSE` where it is drawn, and `PISGA0` at rest, widened 16 columns either way and 16 rows down when any command of the script moves. A script under 18 tics is refused, since the pistol is still rising.

The ticket's interim idle was wrong about vanilla, which matters to ticket 11: `P_UpdateSpecials` shows frame `(t + i) mod count` for picture number `i`, so an animation's phase depends on its first frame's flat or texture number, and no tic shows every animation's first frame. For Freedoom (numbers read from the WAD in nushell): NUKAGE1 is flat 122 of 3, FWATER1 flat 141 of 4, SFALL1 texture 502 of 4, WFALL1 texture 494 of 4. The water and the nukage show the map's frame when the tics run are 57 to 64 (mod 96); the two falls never do then, and want 81 to 88. The default idle is 57, which is enough for every position below.

Differing pixels, one shot each, Freedoom:

| place | script | differing |
| --- | --- | --- |
| -416 256 0 (start) | 57 idle | 0 |
| 736 464 135 | 57 idle | 0 |
| -416 256 90 | 57 idle | 0 |
| 137 256 45 | 57 idle | 0 |
| -416 256 180 | 57 idle | 0 |
| 3 256 0 | 57 idle | 0 |
| -640 256 90 | 57 idle | 0 |
| 488 256 0 | 57 idle | 0 |
| start, the stride | `25,0,0,0,0 34,50,0,0,0` | 0 |
| start, the airborne tic | `4,0,0,0,0 56,50,0,0,0` | 44623 |
| start, the landing | `90,0,0,0,0 66,50,0,0,0` | 40708 |
| start, turning | `53,0,0,0,0 4,0,0,-16,0` | 0 |
| start, walking while turning, then strafing | `20,25,0,8,0 37,0,-24,0,0` | 0 |

The walked scripts idle first so that the frame lands in the water's window; the idle moves nothing but the bob's clock, and both sides run the same script. The stride is the first walked frame ever compared, and the bob is vanilla's to the pixel.

The airborne tic and the landing differ because the ledge the run leaves is Freedoom's lift: the run crosses its special 88 line, vanilla lowers it, and Bendoom has no lift until ticket 08. It is not the fall: with every line special zeroed in a throwaway copy of the tool, both scripts report 0, and so do the last tic on the ledge and the first airborne one (`9,0,0,0,0 48,50,0,0,0`, `8,0,0,0,0 49,50,0,0,0`). Ticket 08 compares these two again with the lift in; the render test's `air` and `landed` pins and the sim test's ledge walk are pins of a level without its lift, and will move then.
