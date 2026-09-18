# 06: The game plays the music

**What to build:** The game streams its package's render to `Audio`. It opens `Audio` at 44100 Hz when its loop starts. Each frame a write of no samples reads the queue, and the game reads enough frames from the current file to bring the queue to 3072 frames, each left and right sample an F32 over 32768. It plays the first pass once, then the second pass forever by opening it again at its end. The wrapper defaults `BENDOOM_MUSIC` beside `BENDOOM_IWAD`, and the dev shell sets it to Freedoom's render. A missing device or missing files leave the game silent with one line on stderr. The music keeps playing through the level's end and a restart, and quitting closes the device and the file.

**Blocked by:** 05 (The repeat and the render node)

**Status:** ready-for-agent

- [ ] `tests/music.bend` streams the Freedoom render in pieces of varying frame counts on both lanes and prints the samples at the start, on either side of the first-pass boundary and on either side of the second pass's wrap, with expected values read from the files in nushell
- [ ] `nix/tests.nix` gets the Freedoom render and sets `BENDOOM_MUSIC`
- [ ] A law says the position after `a` frames and then `b` frames equals the position after `a + b`; closed laws pin both boundaries at Freedoom's pass lengths
- [ ] F32 appears only where samples go to `Audio.write`
- [ ] No automated check opens a sound device
- [ ] Both packages play their song on the dev machine, heard through at least one repeat
