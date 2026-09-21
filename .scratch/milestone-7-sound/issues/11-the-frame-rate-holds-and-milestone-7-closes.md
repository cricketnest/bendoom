# 11: The frame rate holds and milestone 7 closes

**What to build:** The measurement, the erasure pass and the README line that close the milestone.

**Blocked by:** 08 (The film carries the sounds), 09 (The fight sounds), 10 (The intermission sounds)

**Status:** resolved

- [x] The window holds 35 frames a second in Freedoom's first fight with sounds and music, with no dry frame after the first; the ticket records the machine, the power state and the range
- [x] `nix flake check` passes on both lanes, and the proof checks all terms
- [x] The erasure pass: every def is used, no comment describes the music-only stream, no stale claim of silence remains in the source, the README or the specs
- [x] Both packages are played with sound by the maintainer through a fight
- [x] The README's milestone 7 line and the spec's status say done

## Automated verification

On an x86_64 benchmark host on AC power, with the balanced power profile and
`balance_performance` energy preference, the Xvfb bench rendered 600 frames
of the first fight with the real song and effects at 51–55 FPS after the
final melee and damage integration. Six runs at the selected 2304-frame
queue, including the final binary's first run, each had only the initial dry
frame. The same route showed that 2048 fails cold,
1536 is unreliable (one of three runs had four dry frames), and 1024 is too
small (156 and 158 dry frames).

The audio device was a 44100 Hz PipeWire null sink whose monitor showed
nonzero audio; no hardware output was linked. The erasure scan removed the
last unused channel-model accessor and replaced the spec's old silent-level
and 3072-frame descriptions. Ticket 09 verifies the current native Bend
mixer against Chocolate Doom over 228327 aligned stereo frames with zero
differing samples. The final x86_64-linux `nix flake check` passes all
18 tests on native and JavaScript and prints `All terms check.` for the
proof. Real macOS playback still needs a hardware test.

## Play-through

21 Sep 2026. The maintainer played both packages on `a3126db` with sound through their fights to the intermission.
