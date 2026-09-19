# 01: The sim reports its sounds

**What to build:** The replay answers which sounds each tic started and stopped. Everything that already moves in E1M1 reports its sound where vanilla calls `S_StartSound`: doors, the lift, lowering floors, switches and their pop-back, the exit switch, the grunt of a use on a bare wall, the locked door, each pickup family, and the player's landing. The sim also carries vanilla's second random index, which `S_StartSound` advances for every audible start. This is the shared root of milestones 6 and 7: milestone 6's action tickets start their sounds through what this ticket builds.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] The state holds the tic's sound starts and stops, cleared at each tic's start; a start names the sound and its source (a thing by identity, a sector, or nobody), a stop names a source
- [ ] A sector's sound origin is the centre of its bounding box, computed at load, as vanilla's `soundorg`
- [ ] `S_AdjustSoundParams` runs in the sim against the player for every start with a source: a start beyond the clipping distance is dropped, and an audible one carries vanilla's volume and separation
- [ ] The second random index advances once for each audible start except the item pickup sound, as `S_StartSound` draws for a pitch it never uses, and begins where vanilla's stands after the level's wipe; the ticket records how that start value was derived from Chocolate Doom's source
- [ ] The sound table holds the lump name and priority of each sound reported here, and nothing else
- [ ] Removing a thing stops its sound, as `P_RemoveMobj` does
- [ ] The sim test's existing door, lift, switch, exit, locked door, pickup and fall cases print their sounds, with expected sounds and tics read from linuxdoom-1.10's source, and the second random index at each case's end
- [ ] New cases place a sounding door hard left, hard right, behind, at the close distance, and just inside and outside the clipping distance; volumes and separations are worked by hand from the source
- [ ] Closed laws pin volume and separation at those places; replay composition still holds
- [ ] Existing outputs change only by the added sound lines
