# 09: The app runs the sim at 35 tics per second from held keys

**What to build:** The first playable build: walking around the debug map with the keyboard at Doom's speed on any machine. The app layer owns time: it reads the clock, computes elapsed tics at 35 per second with an accumulator, calls the pure step that many times, and caps the catch-up so a stalled frame cannot snowball. Frames stay paced at the runtime's 60 Hz. Key events fold into the held word between tics. Esc and Close quit.

**Blocked by:** 07 (Top-down debug view), 08 (The player moves)

**Status:** resolved

- [x] Holding W or up moves the dot forward across the map; left and right arrows turn it; A and D strafe; Shift runs
- [x] Movement advances by wall-clock tics, not frames: a frame that takes several tics runs several steps
- [x] The catch-up is capped so a long stall runs at most a fixed number of tics
- [x] Esc or closing the window quits
- [x] The game builds and runs with both Freedoom and the shareware WAD

## Comments

Done. `doom.bend` runs its own frame loop (Base's `App.run` drops each frame with a GPU mark, which makes the binary compile for the GPU at launch): each frame folds the key events into the held keys, reads the clock, adds the elapsed milliseconds times 35 to an accumulator in thousandths of a tic, runs at most eight tics, and keeps the remainder. Esc and Close quit. Built and run with Freedoom and the shareware WAD; the game window could not be screenshotted on this session's display, so the view was checked by counting lit pixels in the frame instead.
