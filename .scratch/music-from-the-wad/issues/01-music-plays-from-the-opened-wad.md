# 01: The music and the sounds come from the WAD the game opened

**What is wrong:** Milestone 8 runs Bendoom's music code, and milestone 7 its sound expansion, written in Bend, while the flake builds, so each package plays the song and the sounds of the WAD it was built with. The game reads everything else from the WAD it opens at runtime, which is why it plays Freedoom and the shareware levels alike. Point `BENDOOM_IWAD` at another WAD and the levels change while the song and the sounds stay the same.

**Why it waits:** until the game plays more than E1M1, one song and one set of sounds per package is all it needs. The maintainer chose the build-time render on 18 Sep 2026 to ship milestone 8 fast, and milestone 7's ticket 04 put the sounds beside it on 19 Sep 2026, with this ticket as the way back for both.

**Blocked by:** milestone 8, milestone 7, and the game playing more than one map

**Status:** needs-triage (the maintainer decides when the game generalizes)

## What to build

The game runs milestone 8's song reader, player and chip itself, and milestone 7's lump reader and expansion, on the lumps of the WAD it opened, and writes their samples to `Audio` as it makes them. The render node, the sounds node, their files and the streaming from disk go. The work is speed: milestone 8 records how fast the render runs against real time, and that number says how much faster the code must get to keep the queue fed beside a frame. If it can't, the song renders when the map loads and the ticket records how long that takes. The sounds are the cheap half: milestone 7's ticket 03 expands all 67 of Freedoom's in 1.7 s natively, so expanding a level's at load costs under a second, and a sound could as well be expanded at its first play.

- [ ] Each map's song plays from the WAD the game opened, with that WAD's `GENMIDI`
- [ ] Each map's sounds play from the WAD the game opened
- [ ] `tools/listen.nu` still reports zero differing samples over the first two passes and over the sound captures
- [ ] The frame rate still holds with the music playing, with no empty queue after the first frame, or the load-time render's cost is measured and recorded
- [ ] The render node, the sounds node, the music files, the sound files, `BENDOOM_MUSIC`, `BENDOOM_SOUNDS` and the README's build-time wording are deleted

## Comments

19 Sep 2026, milestone 8's ticket 08, on an x86_64 benchmark host on AC power, balanced profile. The render as it stands runs natively on one thread at about 10 to 11 times real time. Freedoom's two passes, 11,519,771 frames (261.2 s), took 24.2 to 25.4 s in ticket 05 and 22.6 to 23.6 s in ticket 08, 450,000 to 510,000 frames a second. The shareware passes, 8,472,903 frames (192.1 s), took 17.9 to 20.5 s in ticket 05 and 16.6 s in ticket 08. perf puts 95% of the cycles in the chip, `Opl.mix` and the runtime's loops under it, and under 2% each in the song loop and the write (ticket 05's review). Every operator runs every sample whether it sounds or not, so the cost does not depend on the song, and `bench/chip.bend` alone runs at 16 to 17 times real time.

What that means for the game:

- Rendering as it plays fits. A second of music costs about a tenth of a second of the one thread the game runs on. A frame that also renders its own length of song, T = f + T/10, takes 1.1 times what the frame alone takes: milestone 5's key room at 18 ms becomes about 20 ms, 50 frames a second, over the bar of 35. The render would run beside the frame, not ahead of the queue, so a frame longer than the queue's 70 ms still lets it run dry, as it does today.
- Rendering at the map's load does not fit: 23 s for Freedoom's two passes and 16 s for the shareware ones, where the level starts in 13 ms (milestone 5, ticket 12), and Freedoom's 46 MB of passes would then sit in memory or on disk.
- What must move is the chip's state, carried from frame to frame in the game record beside the song's heap and player, 800 to 1260 frames of song a game frame at 55 to 35 frames a second. `Song.turn` already makes a given count of frames and stops, and `Song.out` and `Song.clear` hand them over, which is the seam `music.bend` writes through.

19 Sep 2026, milestone 7's ticket 04, same machine. The sounds now build the same way the song does: `sounds.bend` expands every lump the table in `src/sound.bend` names and `nix/render.nix` runs it once per WAD, so this ticket covers them too. What the sounds add to the work here is small. The node's whole output is 892,620 bytes for Freedoom and 669,152 for the shareware WAD, against the song's 46 MB and 34 MB, and the run takes under a second where the song's takes 25. Ticket 03 measured all 67 of Freedoom's sounds expanding in 1.7 s natively on one thread, of which 0.2 s is reading the 28 MB WAD, and the longest single sound, DSCYBSIT, in about 0.2 s. So the level's sounds can be expanded at load inside a second, or a sound at its first play inside a frame or two, and nothing about the sounds argues for keeping the build-time node. The code to move is `src/sfx.bend`, which is already a pure run a piece at a time; what goes is `sounds.bend`, the `sounds` call in `flake.nix`, `BENDOOM_SOUNDS` and whatever ticket 05's mixer uses to open a sound's file.
