# 03: Freedoom's first pass matches

**What to build:** Freedoom's whole song, once through, sample for sample. The MIDI reader reads every track and event the way `midifile.c` does. The player covers the rest of `i_oplmusic.c`'s Doom 1.9 OPL2 path: note off, voice allocation and stealing in DMX's order, double voices, percussion from the percussion bank, controllers, pitch bend, and tempo changes. Timing follows `opl_queue.c` and `opl_sdl.c`: microseconds from the tempo, equal times popped in the heap's order, generation split at each due callback with the same rounding, and the one F32 rescale of `OPL_Queue_AdjustCallbacks` on a tempo change. `tools/listen.nu` gains the comparison of a render with a capture.

**Blocked by:** 02 (The song's first note sounds as Chocolate Doom's)

**Status:** ready-for-agent

- [ ] `tools/listen.nu` compares a render with a capture after the idle lead and reports the count of differing samples and the largest difference
- [ ] Freedoom's first pass has zero differing samples, or the comments name the cause of each difference and the maintainer accepts it
- [ ] The F32 rescale reproduces C's conversions: int64 to float, float division, truncation back to an integer
- [ ] The Doom 1.666 drivers, OPL3 mode and the debug text are absent
- [ ] The test from ticket 02 grows to a span that crosses a tempo change and a voice steal, still on both lanes
- [ ] Laws are added where a property holds over all inputs of the reader, the queue or the player
