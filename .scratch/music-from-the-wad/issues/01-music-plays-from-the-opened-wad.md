# 01: The music comes from the WAD the game opened

**What is wrong:** Milestone 8 runs Bendoom's music code, written in Bend, while the flake builds, so each package plays the song of the WAD it was built with. The game reads everything else from the WAD it opens at runtime, which is why it plays Freedoom and the shareware levels alike. Point `BENDOOM_IWAD` at another WAD and the levels change while the music stays the same.

**Why it waits:** until the game plays more than E1M1, one song per package is all it needs. The maintainer chose the build-time render on 18 Sep 2026 to ship milestone 8 fast, with this ticket as the way back.

**Blocked by:** milestone 8, and the game playing more than one map

**Status:** needs-triage (the maintainer decides when the game generalizes)

## What to build

The game runs milestone 8's song reader, player and chip itself, on the lumps of the WAD it opened, and writes their samples to `Audio` as it makes them. The render node, its files and the streaming from disk go. The work is speed: milestone 8 records how fast the render runs against real time, and that number says how much faster the code must get to keep the queue fed beside a frame. If it can't, the song renders when the map loads and the ticket records how long that takes.

- [ ] Each map's song plays from the WAD the game opened, with that WAD's `GENMIDI`
- [ ] `tools/listen.nu` still reports zero differing samples over the first two passes
- [ ] The frame rate still holds with the music playing, with no empty queue after the first frame, or the load-time render's cost is measured and recorded
- [ ] The render node, the music files, `BENDOOM_MUSIC` and the README's build-time wording are deleted

## Comments

19 Sep 2026, milestone 8's ticket 08, on an x86_64 benchmark host on AC power, balanced profile. The render as it stands runs natively on one thread at about 10 to 11 times real time. Freedoom's two passes, 11,519,771 frames (261.2 s), took 24.2 to 25.4 s in ticket 05 and 22.6 to 23.6 s in ticket 08, 450,000 to 510,000 frames a second. The shareware passes, 8,472,903 frames (192.1 s), took 17.9 to 20.5 s in ticket 05 and 16.6 s in ticket 08. perf puts 95% of the cycles in the chip, `Opl.mix` and the runtime's loops under it, and under 2% each in the song loop and the write (ticket 05's review). Every operator runs every sample whether it sounds or not, so the cost does not depend on the song, and `bench/chip.bend` alone runs at 16 to 17 times real time.

What that means for the game:

- Rendering as it plays fits. A second of music costs about a tenth of a second of the one thread the game runs on. A frame that also renders its own length of song, T = f + T/10, takes 1.1 times what the frame alone takes: milestone 5's key room at 18 ms becomes about 20 ms, 50 frames a second, over the bar of 35. The render would run beside the frame, not ahead of the queue, so a frame longer than the queue's 70 ms still lets it run dry, as it does today.
- Rendering at the map's load does not fit: 23 s for Freedoom's two passes and 16 s for the shareware ones, where the level starts in 13 ms (milestone 5, ticket 12), and Freedoom's 46 MB of passes would then sit in memory or on disk.
- What must move is the chip's state, carried from frame to frame in the game record beside the song's heap and player, 800 to 1260 frames of song a game frame at 55 to 35 frames a second. `Song.turn` already makes a given count of frames and stops, and `Song.out` and `Song.clear` hand them over, which is the seam `music.bend` writes through.
