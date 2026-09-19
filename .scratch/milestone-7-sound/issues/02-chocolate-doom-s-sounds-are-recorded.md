# 02: Chocolate Doom's sounds are recorded

**What to build:** `tools/listen.nu` records the sound effects Chocolate Doom plays for a demo, with no window, desktop or sound card, as it already records the music. It finds each sound's first frame in the recording. This gives every later audio ticket its outside answer.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] The tool plays a command script as a demo through SDL's disk audio driver in real time, music off by default and on by a flag, at Chocolate Doom's default sound settings
- [ ] It reports the frame at which each sound starts, and the ticket records how far the same demo's starts move between two runs
- [ ] A recording of one use grunt, of a door heard from one side, and of a sound over the music are taken on Freedoom and described in the ticket: length, peak, left against right
- [ ] The ticket lists the sample rate and length of every sound lump in both WADs, read in nushell, and which expansion path of Chocolate Doom each rate takes
- [ ] The ticket records the SDL and SDL_mixer versions the dev shell's Chocolate Doom links, since the resampler is theirs
- [ ] Nothing here runs in the flake check or opens a device on the desktop
