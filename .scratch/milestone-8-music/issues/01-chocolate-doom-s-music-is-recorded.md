# 01: Chocolate Doom's music is recorded

**What to build:** The oracle for the whole milestone. `tools/listen.nu` runs Chocolate Doom from nixpkgs on a given WAD, warped to E1M1 with no monsters and no sound effects, at its default music settings, and records its music to a file through SDL's disk audio driver. Nothing opens a window on the desktop. The tool reports, for the capture, whether left equals right and how many silent samples come before the first note. Later tickets extend it to compare a render with the capture.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] The tool records at least two passes of E1M1's song (about 261 s of audio for Freedoom, 192 s for the shareware WAD) and stops Chocolate Doom by itself
- [ ] The capture is 44100 Hz signed 16-bit stereo, and the tool checks the format it got rather than assuming it
- [ ] The environment names the nixpkgs SDL (sdl2-compat over SDL3) honours for the disk driver, its output file and its speed are found and written in the tool's usage comment
- [ ] Music settings match Chocolate Doom's defaults (OPL, 44100 Hz, volume 8, no `snd_dmxoption`) through a scratch config, not the user's
- [ ] No window opens on the desktop: the video runs on SDL's dummy driver or on Xvfb, as `tools/oracle.nu` does
- [ ] The report gives left-equals-right for the whole capture and the count of silent samples before the first note
- [ ] Two captures of the same WAD are compared, and the comments record whether the lead and the samples after it vary between runs
- [ ] Both WADs are captured and their numbers recorded in the comments; the shareware run is by hand
