# 08: The film carries the sounds

**What to build:** A filmed demo sounds as the game did. The film mixes offline: a tic is exactly 1260 frames at 44100 Hz, so each sound starts on its tic's first frame, mixed over the song by the same channels and mixer and put under the video.

**Blocked by:** 07 (The game sounds)

**Status:** ready-for-agent

- [ ] The film gathers sounds tic by tic through what ticket 07 built for the loop, not a second gatherer
- [ ] The film's audio is the mixer's output for the demo's tics, song and sounds, from frame zero to the video's end
- [ ] The earlier mux of the two music files alone is deleted
- [ ] A test or a recorded check shows a door's sound starting on the frame of its tic in a filmed Freedoom demo
- [ ] Both film packages build, each with its own WAD's sounds
- [ ] The README's film paragraph says the video carries the sounds
