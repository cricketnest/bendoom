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
