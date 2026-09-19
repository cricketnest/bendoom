# 03: One sound expands as Chocolate Doom's

**What to build:** A Bend program reads a sound lump as Chocolate Doom's `CacheSFX` does and expands it to 44100 Hz by the path that lump's rate takes. One expanded sound is compared with ticket 02's recording. This is the risky step of the milestone, so it ends with numbers for the maintainer.

**Blocked by:** 02 (Chocolate Doom's sounds are recorded)

**Status:** ready-for-agent

- [ ] The lump reader checks the header, takes the rate and length, refuses what Chocolate Doom refuses, and drops the padding it drops
- [ ] The expansion follows SDL's converter for rates that divide 44100 by a power of two, and Chocolate Doom's own loop with its low-pass filter for any other rate the two WADs hold; a path no lump takes is not written
- [ ] If SDL's filter table is needed, a nushell tool generates it from SDL's source, as the angle and chip tables are generated
- [ ] The use grunt, expanded and scaled to the recording's volume, is compared with the recording from its first frame: the ticket records the count of differing samples and the largest difference, target zero
- [ ] If zero is out of reach, the ticket stops and brings the numbers to the maintainer before ticket 04 starts
- [ ] The ticket records how long expanding every sound of Freedoom takes on the dev machine, native, so that the build-time decision in the spec rests on a number
- [ ] A test on both lanes expands one Freedoom sound and prints a hash and sampled values read from the recording in nushell
