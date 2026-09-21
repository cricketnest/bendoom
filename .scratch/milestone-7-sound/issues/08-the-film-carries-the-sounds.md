# 08: The film carries the sounds

**What to build:** A filmed demo sounds as the game did. The film mixes offline: a tic is exactly 1260 frames at 44100 Hz, so each sound starts on its tic's first frame, mixed over the song by the same channels and mixer and put under the video.

**Blocked by:** 07 (The game sounds)

**Status:** resolved

- [x] The film gathers sounds tic by tic through what ticket 07 built for the loop, not a second gatherer
- [x] The film's audio is the mixer's output for the demo's tics, song and sounds, from frame zero to the video's end
- [x] The earlier mux of the two music files alone is deleted
- [x] A test or a recorded check shows a door's sound starting on the frame of its tic in a filmed Freedoom demo
- [x] Both film packages build, each with its own WAD's sounds
- [x] The README's film paragraph says the video carries the sounds

## Verification

The Freedoom door route under `/tmp/m6-06/door.lmp` produces 115 video tics and
579600 stereo PCM frames. Comparing the film mix with the same score rendered
without an effects directory finds the first differing byte at zero-based byte
171360: stereo frame 42840, exactly the first frame of tic 34 (`34 * 1260`).
The encoded MP4 has matching 3.285714-second H.264 and AAC streams at 44100 Hz.

Both `film` and `film-freedoom` build. Each derivation supplies the effects
directory made from the same IWAD as its score. The film calls `Play.step`, feeds
its events to `Channel.hear`, updates moving sources, and asks `Stream.window`
for 1260 frames once per tic. The wrapper decodes the resulting audio and video
hex streams and muxes those raw streams; the old music-only inputs are gone.
