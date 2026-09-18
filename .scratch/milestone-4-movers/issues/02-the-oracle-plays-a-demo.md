# 02: The oracle plays a demo

**What to build:** The milestone's risk, taken first. The oracle tool gains one argument, a command script in demo units: runs of a count, then forward, side, the 8-bit turn and use. It writes the script as a version 109 demo with no monsters whose last command presses pause, followed by idle commands, and runs Chocolate Doom with the demo in real time on the player-start PWAD, headless as before. It shoots once inside the paused tail and masks the status bar, the pause graphic (its box read from the WAD's patch) and the pistol widened by its bob's reach. The frame dump reads the same position and script and replays it through the sim before it renders, so both sides run the same commands. A rest position is the script that idles. The eight-shot loop and its varying count are deleted, since a paused tic is one frame.

Until tickets 10 and 11 land, the PWAD still zeroes sector specials and line special 48, and keeps every other line special. Until ticket 11, the rest script idles to a tic where every animation shows its first frame (vanilla's phase is the tics run less one, over 8, so 97 tics covers cycles of three and four), since Bendoom draws only that frame.

This rests on four things nobody here has tried: Chocolate Doom playing a demo file against a PWAD, honouring a pause during playback, keeping the paused tail alive in real time, and taking its screenshot while paused. If the pause does not hold, stop and record what failed in the comments. The fallback in the spec's notes (a use key sent by xdotool and a shot once the mover has settled) is then the maintainer's call.

**Blocked by:** 01 (The sim takes commands)

**Status:** ready-for-agent

- [ ] An idle script at the start position reports zero differing pixels from one shot
- [ ] Every rest position of the render test reports zero from one shot; the counts are recorded in the comments
- [ ] The render test's three walked frames (the stride, the airborne tic, the landing) are compared for the first time, their scripts given in demo units; each count is recorded, and any difference is a sim or renderer bug to fix or to explain in the comments
- [ ] The demo's bytes are vanilla's: the 13-byte header, four bytes a tic, the 0x80 end; checked against linuxdoom's G_ReadDemoTiccmd, not against our own reader
- [ ] The tool's header comment describes the demo, the pause and the masks, and no longer describes eight shots
- [ ] No window opens and no focus moves on the desktop
