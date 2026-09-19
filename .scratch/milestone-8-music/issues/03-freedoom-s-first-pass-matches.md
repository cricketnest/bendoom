# 03: Freedoom's first pass matches

**What to build:** Freedoom's whole song, once through, sample for sample. The MIDI reader reads every track and event the way `midifile.c` does. The player covers the rest of `i_oplmusic.c`'s Doom 1.9 OPL2 path: note off, voice allocation and stealing in DMX's order, double voices, percussion from the percussion bank, controllers, pitch bend, and tempo changes. Timing follows `opl_queue.c` and `opl_sdl.c`: microseconds from the tempo, equal times popped in the heap's order, generation split at each due callback with the same rounding, and the one F32 rescale of `OPL_Queue_AdjustCallbacks` on a tempo change. `tools/listen.nu` gains the comparison of a render with a capture.

**Blocked by:** 02 (The song's first note sounds as Chocolate Doom's)

**Status:** done

- [x] `tools/listen.nu` compares a render with a capture after the idle lead and reports the count of differing samples and the largest difference
- [x] Freedoom's first pass has zero differing samples, or the comments name the cause of each difference and the maintainer accepts it
- [x] The F32 rescale reproduces C's conversions: int64 to float, float division, truncation back to an integer
- [x] The Doom 1.666 drivers, OPL3 mode and the debug text are absent
- [x] The test from ticket 02 grows to a span that crosses a tempo change and a voice steal, still on both lanes
- [x] Laws are added where a property holds over all inputs of the reader, the queue or the player

## Comments

19 Sep 2026. Chocolate Doom 3.1.1 from the flake's nixpkgs, Freedoom 0.13.0, on an x86_64 benchmark host on AC power, balanced profile.

The first commit is ticket 02's review: `src/music.bend` is `src/song.bend`, the callback heap is `Song.heap`, one write shape (`Opl.Write{reg, val}`, and `Opl.Pending` pairs one with its due sample), `Maybe` for a voice with no channel, a register with no channel and a heap entry with no child, a match wherever a branch builds, one lump lookup (`Wad.find`), one hash (`Opl.hash`) and one main (`Song.load`). The MIDI reader hands the player a `Tempo` event. The flake test's output did not change in it.

What landed. The MIDI reader reads tracks as `ReadTrack` does, from each header to its end-of-track, with the next header right after; the chunk length is not read, and no track is copied, so no track length is a recursion depth on the JS lane. Sysex events (0xF0, 0xF7) read their length and skip that much data. The player has note off, a note on of velocity 0 as a note off, all notes off (controller 123), `ReleaseVoice` (the key-off write, the channel cleared, the voice to the end of the free list) and the Doom 1.9 driver's `ReplaceExistingVoice`. A voice stores the MIDI key `KeyOffEvent` matches, apart from the note it sounds. The song counts the running tracks and schedules the restart 5 ms after the last one ends; the pass ends where the restart is due. `OPL_Mix_Callback`'s loop is one step type: cut, call a track, or stop. `tools/listen.nu render <capture>` compares any span of `tools/render.bend`'s output with a capture (`--frames`, the whole first pass without it) and replaces `listen.nu opening`.

The comparison. The first pass is 5,763,979 frames: the 4096 idle frames and 5,759,883 of song. Against two new real-time captures, whose leads are 4536 and which agree over their 11,935,304 shared frames, 0 left and 0 right samples differ, largest difference 0. A capture shifted one frame reports 5,728,510 left and 5,728,505 right samples differing from frame 4535, so the comparison sees a difference when there is one. The pass drives 2419 voice steals, the first a note on channel 9, key 36, whose callback runs after frame 67613.

The rescale. `OPL_Queue_AdjustCallbacks` in the nixpkgs binary is `cvtsi2ss` (the int64 offset to float, rounded to nearest), `divss`, then `cvttss2si` below 2^63, so an offset below zero truncates toward zero and lands before now. `Song.rescale` takes the offset's magnitude through `U32.to_f32`, divides, truncates with `F32.to_u32` and puts the sign back, which is the same, since rounding, division and truncation are symmetric in sign. Values worked by hand from C's conversions, with the factor (float) 500000 / 480000: 136,000,000 µs becomes 130,560,008 (track 17's first callback, as ticket 02 found), 993 at now 1000 becomes 994 (-7 / 1.0416666 = -6.72), and 90 at now 100 with factor 0.75 becomes 87. The render gives all three on both lanes. The song has three tempo events, two at tick 0 (500000 to 480000 µs a beat) and one at 130.565 s (480000 to 480000). The third meets one overdue callback in the heap, so C's negative path runs in Freedoom, though with a factor of exactly 1.

The write buffer. The pass never has more than 360 writes pending, the setup's, so `OPL3_WriteRegBuffered`'s path past 1024 (opl3.c:1344) never runs. It is not ported, and a song that could reach it needs it ported first.

The largest MIDI lump `i_oplmusic.c` takes is under 96 KiB (`MAXMIDLENGTH`), which bounds the events a track walk reads. The reader does not port `MIDI_GetFileTimeDivision`'s SMPTE branch (a negative division), a status byte from 0xF1 to 0xFE, or a variable-length number of five bytes, where `midifile.c` fails the load; neither WAD's song has any of them.

The speed. The whole pass renders natively in 9.0 to 9.5 s over three runs with only a hash printed, 14 to 15 times real time, and in 9.5 to 10.7 s with every frame printed as hex, 12 to 14 times. Most of it is the chip. The render holds the pass in memory; ticket 05 writes it as it is made.

The test. `tests/music.bend` renders the first 72000 frames: the idle buffer, the two tempo changes at tick 0 (which rescale every track's first callback and set the tempo later events are scheduled at), the first note and the first voice steal. It prints the frame count, the hash and seven frames, read from the first capture in nushell with the commands in its header (both captures give the same lines). It runs in 0.2 s native and 4.3 s on bun. Removing the voice steal changes the hash and the frames after it, and so does ignoring the tempo events. The song's only later tempo change is at 130.5 s, which the JS lane would take about four minutes to reach at its 25,000 frames a second; the whole-pass comparison covers it.

The laws. `sysex_skipped` and `end_of_track_ends` hold whatever bytes follow; `heap_one` for any entry; `heap_ties` pins that equal times do not pop in push order (the third pushed runs second); `velocity_zero_is_off` for any player; `quiet_offs` for any channel, key and velocity. A false `heap_ties` fails the proof. The rescale has no law: F32 does not compute in the checker.

Commands:

    tools/listen.nu --keep                                      (twice)
    tools/listen.nu compare <a> <b>
    bend tools/render.bend -o render
    tools/listen.nu render <a>; tools/listen.nu render <b>
    time ./render --threads 1 > /dev/null                        (three times)
    nix build .#checks.x86_64-linux.tests .#checks.x86_64-linux.proof

For ticket 04:

- The song reaches the player as `Midi.Event`s (`Chan`, `Tempo`, `End`, `Other`) from `Midi.next` and `Midi.delta` on a `Midi.Track`. A MUS reader that answers the same two questions per track needs no change in `song.bend`.
- Check the shareware pass's most pending writes. Past 1024, port opl3.c:1344 first.
- `tools/listen.nu render` compares any span; a shareware capture needs `--length 200sec`.

For ticket 05:

- The pass ends with the restart due at song frame 5,759,883, one more than ticket 01's period of 5,759,882, which was found by matching audio 20 s into each pass. `RestartSong` writes nothing to the chip, so the first pass's samples do not pin the frame it runs on; the second pass's comparison will.
- `RestartSong` restarts every track at now, sets the running count back, and runs `InitChannel` on the channels but not `InitVoices`: the voices, their instruments and the write buffer carry over. Where `Song.play` stops at `Stop{}`, the repeat runs the restart instead.
- `Song.render` holds all the frames it makes. The render node must write them as each cut is made.
