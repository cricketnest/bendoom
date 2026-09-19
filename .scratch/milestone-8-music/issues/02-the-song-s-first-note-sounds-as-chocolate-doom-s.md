# 02: The song's first note sounds as Chocolate Doom's

**What to build:** The narrow path from WAD to samples, in Bend. A nushell tool generates Nuked OPL3's log-sine and exponent tables from Chocolate Doom's `opl/opl3.c`. The chip is written in Bend for what DMX drives, with the buffered register writes and the integer conversion to 44100 Hz. The player sets up the chip as Chocolate Doom does and starts a note with its GENMIDI instrument, volume and frequency. The song reader reads Freedoom's MIDI lump far enough to reach its opening. The result is Freedoom's opening, from the song's start to the first event after its first notes, rendered after the capture's idle lead and compared with ticket 01's capture. The chip's speed is measured before anything is built on it.

**Blocked by:** 01 (Chocolate Doom's music is recorded)

**Status:** done

- [x] The table tool regenerates the tables module byte for byte from `opl3.c`, and the module names the tool at its top
- [x] The chip carries two-operator voices, waveform select, note select, tremolo, vibrato, the envelope generator and its global timer, key scaling, feedback and both connections, and nothing Doom's player does not write
- [x] Register writes go through the delay buffer of `OPL3_WriteRegBuffered`, and output goes through `OPL3_GenerateResampled`
- [x] The player's chip setup and note start follow `i_oplmusic.c` for the Doom 1.9 driver in OPL2 mode, at music volume 8
- [x] How much of the capture's 4536-frame lead is idle chip, and how much is the song's scheduling and the first note's attack, is worked out from Chocolate Doom's source and recorded
- [x] The opening's left and right samples equal the capture's after the idle lead; the count of differing samples is recorded, target zero
- [x] The chip's samples a second against real time are measured natively on the dev machine and recorded; below a tenth of real time, the ticket stops and brings the number to the maintainer
- [x] A test in the flake check renders the opening on both lanes and prints a hash and sampled values taken from the capture in nushell

## Comments

19 Sep 2026. Chocolate Doom 3.1.1 from the flake's nixpkgs, Freedoom 0.13.0, on an x86_64 benchmark host on AC power, balanced profile.

What landed. `tools/gen_opl_tables.nu` writes `src/opl_tables.bend` from the Chocolate Doom source: Nuked's log-sine and exponent ROMs, and DMX's frequency curve and volume mapping. `src/opl.bend` is the chip, `src/midi.bend` reads the song's tracks an event at a time, `src/player.bend` is DMX's player as far as note start, and `src/music.bend` schedules it as `opl_sdl.c` and `opl_queue.c` do. `tools/opening.bend` prints the opening's frames as hex. `tools/listen.nu opening <capture>` compares them with a capture from frame 0, left and right apart. `tests/music.bend` runs in the flake check and `bench/chip.bend` times the chip. `src/bytes.bend` gained `Bytes.list`, a byte run read by a loop whose body is not recursive, so a 50 KB lump costs no stack on the JS lane.

The lead. The capture's 4536 silent frames are one buffer of idle chip and then 440 frames of the song itself. No scheduling delay sits between them. Ticket 01 read the buffer as 1024 frames. It is 4096: `GetSliceSize` (opl_sdl.c:266) takes the largest power of two not over 100 ms, 4410 frames at 44100 Hz, and `Mix_OpenAudioDevice` (opl_sdl.c:303) opens the device with it. A gdb trace of the real-time run (breakpoints on `OPL_Mix_Callback`, `OPL3_GenerateStream`, `OPL3_WriteRegBuffered` and `I_OPL_PlaySong`, nothing added to the repo) confirmed 16384 bytes a callback. In order:

- `OPL_SDL_Init` resets the chip (opl_sdl.c:352) and registers the mixing callback (opl_sdl.c:361) before any buffer reaches the file, so capture frame 0 is chip frame 0.
- `InitDriver` runs `OPL_Detect` twice (opl.c:85). Each waits on `OPL_Delay(1 ms)` (opl.c:307), which returns only once the audio thread fires its callback. The first fires 45 frames into buffer 1 (the rounding at opl_sdl.c:210). The second fires at the buffer's end. Detection writes only timer registers, which `WriteRegister` keeps from the chip (opl_sdl.c:405).
- `OPL_InitRegisters` (opl.c:339) then queues 234 writes to the chip. The rest of the startup and the level load finish inside buffer 2's wait, and `I_OPL_PlaySong` (i_oplmusic.c:1476) schedules every track's first event at the current time. All of Freedoom's tracks start at tick 0.
- Buffer 2 starts with a cut of zero frames (opl_sdl.c:202 to 217), and `AdvanceTime(0)` runs every tick-0 event before frame 4096. So frames 0 to 4095 are idle chip: 4618 chip samples.
- `OPL3_WriteRegBuffered` (opl3.c:1340) dates each write two chip samples after the last, starting from the sample count, and `OPL3_Generate` applies it after the sample of that number (opl3.c:1164). The song's first write therefore waits behind the 234 setup writes, until chip sample 5086, made in frame 4511. Voice 0's key-on is the song's 14th write, due after sample 5112. The first sample with its key down is made in frame 4535. Frame 4536 is the first other than zero.

Of the 440 frames, 415 are the setup writes draining, 24 are voice 0's own writes before its key-on, and the last is the attack. The source decides all of it except two races. The song starts in buffer 2 only because the game reaches the level within one 93-ms buffer. And `SDL_PauseAudio(0)` (opl_sdl.c:311) starts the device before `OPL3_Reset` (352) and `Mix_RegisterEffect` (361), so capture frame 0 is chip frame 0 only because no buffer reaches the file between them. Every real-time capture so far agrees: ticket 01's 13 and both of mine.

The render runs the chip idle for exactly the first buffer. As a control, a render with two idle buffers, aligned to the capture at the song's start, differs on 9648 of 18778 samples, by up to 1932.

The comparison. The opening runs from frame 0 to frame 9389, where track 2's first note-offs at tick 24 fire. That is song frame 5293 and not 5292, because each cut's microseconds round down. Against two real-time captures, 0 left samples and 0 right samples differ, over all 9389 frames. The 360 register writes also equal the trace's, in order and value, due from chip sample 4618 to 5336, two apart. The opening sounds six notes on nine voices (three double-voice instruments), with waveforms 0, 2 and 3, vibrato, feedback and connection 0. Tremolo, waveform 1, connection 1 and release after a key-off are ported but untested. The first pass will test them.

The speed. `bench/chip.bend` renders 100 s of the chip with one note held, in 5.95 to 6.30 s on one thread over three runs: 700,000 to 741,000 frames a second, 16 to 17 times real time. The bar was a tenth of real time. Every operator runs every sample whether it sounds or not, so the chip's cost does not depend on the song. The opening renders in 0.16 s native and 1.0 s on bun.

The test. `tests/music.bend` prints the frame count, an FNV-1a hash of the 9389 frames as 32-bit words, and six frames: 4535, 4536, 4537, 6000, 8000 and 9388. The expected lines were read from the first capture in nushell with the commands in the test's header comment. Frame 4536 is left 29, right 0. The right side lags, as ticket 01 found, because it is the mix of the previous chip sample.

Commands:

    nix build --no-link --print-out-paths --inputs-from . nixpkgs#chocolate-doom.src
    tools/gen_opl_tables.nu <that path> | save --force src/opl_tables.bend
    tools/listen.nu --length 10sec --keep                  (twice)
    bend tools/opening.bend -o opening
    tools/listen.nu opening <capture>                      (both captures)
    bend bench/chip.bend -o chip; time ./chip --threads 1  (three times)
    nix build .#checks.x86_64-linux.tests .#checks.x86_64-linux.proof

For ticket 03:

- The player leaves out note off, a velocity-0 note on, all notes off (controller 123), `ReplaceExistingVoice` and sysex events. The opening ends before any of them. With no free voice it drops the note, where the Doom 1.9 driver frees one first. `running_tracks` and the restart are absent too.
- `Music.adjust` assumes every queued callback is at or after now. C converts a negative offset through float to `uint64_t`, which lands before now. That case can arise when a tempo change runs while other callbacks due at the same moment wait in the queue after a cut overshot their time. Freedoom's third tempo event, at tick 26113, is one tick after other tracks' events.
- `Opl.queue` has no ring: past 1024 pending writes, C applies the oldest at once and moves the sample count (opl3.c:1344). The opening peaks at 360.
- The heap is a list with O(n) reads and writes, at most 18 entries here. Freedoom's track 17 lands at 130,560,008 µs, not 130,560,000, because the first tempo change rescales its callback in single precision.
- The largest track is 14054 bytes. `Midi.tracks.one` takes each with `List.take`, which recurses once a byte, so a song with a track past about 20000 bytes needs another reader on the JS lane.

For ticket 05: the setup writes are part of the song. A render that skips the idle buffer still queues them first, and its first write is due at chip sample 2 (the later of the last write's time plus two and the count, both 0), not at the count.
