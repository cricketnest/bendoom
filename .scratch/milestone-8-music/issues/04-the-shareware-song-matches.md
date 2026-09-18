# 04: The shareware song matches

**What to build:** The MUS reader. A MUS lump goes straight to the events and delays the player reads, with `mus2mid.c`'s channel, controller and velocity mapping and its timing, and no MIDI bytes built in between. A lump that is neither MUS nor MIDI fails the render. The shareware song's first pass is compared with its capture.

**Blocked by:** 03 (Freedoom's first pass matches)

**Status:** ready-for-agent

- [ ] Expected event counts and the song's length (13440 ticks at 140 a second, 96.0 s) are read from the lump in nushell before the Bend code answers
- [ ] The shareware first pass has zero differing samples against its capture, run by hand because the WAD is unfree, and the numbers are recorded
- [ ] A lump that is neither format fails the render with a message naming the lump
- [ ] A closed law or a test on a small literal MUS lump in the flake check covers the mapping without the unfree WAD
