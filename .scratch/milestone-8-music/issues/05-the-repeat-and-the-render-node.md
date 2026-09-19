# 05: The repeat and the render node

**What to build:** `music.bend` renders a WAD's song to two files and the build graph runs it. The render runs the song looping and cuts at the sample where the player's restart callback runs, 5 ms after the last track ends. The first file holds the first pass and the second file the second pass, raw signed 16-bit little-endian stereo at 44100 Hz, written with `Bytes.write` chunk by chunk. `nix/music.nix` builds and runs it for one IWAD, and the render's cost is measured.

**Blocked by:** 03 (Freedoom's first pass matches), and the demo recording work on main for `Bytes.write`

**Status:** done

- [x] The second pass starts with the tails of the first pass's last notes, and both passes equal the capture after the idle lead
- [x] The render never holds a whole pass in memory
- [x] The music is a function of the IWAD in the flake; the shareware render is built only with the shareware packages
- [x] Two builds of the Freedoom node give identical files
- [x] The Freedoom node's build time and the render's samples a second against real time are recorded

## Comments

19 Sep 2026. Chocolate Doom 3.1.1 from the flake's nixpkgs, Freedoom 0.13.0, on an x86_64 benchmark host on AC power, balanced profile.

The first commit merges the `recording` branch for `Bytes.write`.

What landed. `music.bend` renders the song of the WAD named by `BENDOOM_IWAD` into the current directory: `first.raw`, from the song's start to the frame where its restart runs, and `second.raw`, from there to the next restart. Both are raw S16LE stereo at 44100 Hz, left then right. Each cut is written with `Bytes.write` as it is made. `Song.next` runs the callbacks that are due and then one cut, and `Song.clear` drops the frames once they are written. Nothing holds more than one cut, at most 4096 frames. `Song.restart` is `RestartSong`: it pops the restart, starts every track again from now with the tempo the pass ended on, and runs `InitChannel`. It shares `Song.begin` with the song's start. Voices, instruments and the chip's write buffer carry over. With `BENDOOM_IDLE` set, the chip first makes Chocolate Doom's idle buffer, as a capture does. `tools/listen.nu render <capture>` runs a built `./music` that way in a scratch directory and compares both passes. `tools/render.bend` is gone.

Ticket 03's review is in `src/song.bend`:

- A heap entry is one shape, `Entry{time, track: Maybe}`, where no track means the restart. `Song.time`, `Song.adjust` and the step no longer split Next from Restart.
- The step is `Cut{d}` or `Call{track}`. `full → Stop{}` is gone with the span, and so is the second `Cut{Song.wait(..)}`.
- 100000 appears once, in `Song.step.at`.
- An empty heap reads as an entry never due (`Song.at`'s default). A cut then takes the buffer's rest, as `opl_sdl.c` does with an empty queue, and the `None` branch of `Song.step.top` is gone.
- The song's division moved into `Song.Env` beside the MIDI file, since it never changes.
- The buffer size is named once (`Song.buffer`).
- `BENDOOM_FRAMES` and its 4294967295 went with `tools/render.bend`.

The repeat against Chocolate Doom. Two new real-time captures, each with a lead of 4536 (11,939,840 and 11,943,936 frames). The idle render's passes are 5,763,979 frames (4096 idle, then 5,759,883 of song) and 5,759,888 frames. Over all 11,523,867 frames, against both captures, 0 left and 0 right samples differ, largest difference 0. So the restart runs after song frame 5,759,882, and song frame 5,759,883 is the second pass's first frame. The first pass is 5,759,883 frames, one more than ticket 01's period of 5,759,882, which matched audio 20 s into each pass and so measured something else. The second pass is 5 frames longer than the first, since it is not the first shifted (the handoff's tempo and overshoot). As a control, a render whose restart is due 23 µs later (5023 µs in place of 5000) makes a first pass one frame longer. It differs on 5,727,676 left and 5,727,953 right samples from frame 5,763,983 (song frame 5,759,887), largest 2919. The comparison therefore sees a restart one frame off. The shipped render, with no idle buffer, has the same pass lengths: 5,759,883 and 5,759,888 frames, 23,039,532 and 23,039,552 bytes. The last frames of `first.raw` (233, 247) run straight into the first of `second.raw` (216, 229): the tails carry over.

Memory. During a run the resident size stays at 142 MB from the first second to the last, while the files grow to 46 MB. It is the runtime's arena, not the song.

The node. `nix/music.nix` builds the render program once (`bendoom-music-render`, which depends on no IWAD) and runs it for one IWAD. In `flake.nix`, `music = iwad: ...` is the IWAD-to-music function, and `packages.music` is Freedoom's. Nothing else calls it yet, so the shareware render builds with nothing, and certainly not with the flake check. Tickets 06 and 07 pass the function to `bendoom.nix` and `film.nix` so that `override { iwad = ...; }` carries the music along. The shareware render cannot run until ticket 04's MUS reader lands. Timings:

- Cold build of the Freedoom node: 28.6 s. That is 3.7 s to compile the program and about 24.5 s to render.
- `nix build .#music --rebuild` gave the same files: first.raw sha256 53300d93…0f79, second.raw fa584f30…9162.
- `--rebuild` of the render program's derivation also passed.

The speed. Three runs of the shipped render took 24.19, 24.34 and 25.02 s for 11,519,771 frames (261.2 s of audio). That is 460,000 to 476,000 frames a second, 10.4 to 10.8 times real time. With the write removed, one run took 22.5 s, so writing costs about 2 s. Ticket 03's render of one pass, rebuilt from 8dadefc, took 9.2 to 9.5 s today; this program's passes take about 11.2 s each without the write. perf finds the chip (`Opl.mix` and the runtime's `spin_*` loops) at the top of both profiles. Neither the song loop nor the write appears, so the 20% is in how the same chip code compiles within this program. I did not chase it further.

The test. `tests/music.bend` now runs `Song.start` idle and `Song.next` until 72000 frames are made, then drops the last cut's overshoot. It prints the same hash and frames as before, less the frame count, which the span used to pin. Native 0.2 s, bun 3.6 s. `List.take` over 72000 frames overflowed bun's stack; `List.drop` is a tail loop.

Commands:

    tools/listen.nu --keep                                      (twice, side by side)
    bend music.bend -o music
    tools/listen.nu render <a>; tools/listen.nu render <b>
    tools/listen.nu render <a> --binary <music with the restart at 5023 µs>
    time ./music --threads 1                                    (three times, in a scratch dir)
    nix build .#music; nix build .#music --rebuild
    nix build .#checks.x86_64-linux.tests .#checks.x86_64-linux.proof

For tickets 06 and 07:

- `music iwad` in `flake.nix` gives a store path holding `first.raw` (5,759,883 frames for Freedoom) and `second.raw` (5,759,888). Play `first.raw` once, then `second.raw` forever.
- To make the music follow the IWAD, take `music` (the function) as an argument of `bendoom.nix` and `film.nix`, and apply it to their own `iwad` inside, so `bendoom-shareware` and `film-shareware` get the shareware render. `nix/tests.nix` can take `music freedoom` for `BENDOOM_MUSIC`.
- `Song.turn`/`Song.out`/`Song.clear` is the seam if the game ever renders as it plays.

Review. 19 Sep 2026, same machine and power state. The standards and spec reviews of tickets 04 and 05, fixed on branch m8-45-fixes from cfec5e1.

`Song.next` ended the pass without a word when its fuel ran out, so the render would have restarted early and exited 0. It is gone. `Song.turn` runs `OPL_Mix_Callback` until the frames asked for are made or the restart ends the pass, and answers `More`, `Ended` or `Stuck`. On `Stuck` the render exits 1 with `D_E1M1: a song whose callbacks outran the events a lump holds`. The fuel is one turn per frame asked plus `Midi.most()`, 98320, one per event a lump can hold. That bound holds again because the reader now refuses a MUS lump of 96 KiB or more, as `I_OPL_RegisterSong` does. Before, only MIDI lumps were held to it, and the error message already claimed the limit for both. The old comment's bound is deleted. `music.bend` and `tests/music.bend` both call `Song.turn`, the first a buffer at a time and the second once for 72000 frames, so `Test.render` is gone.

`Song.load` returns the `Song.Env` it checked, and the check reads the file in it, so the lump is parsed once. `Song.Lumps`, `Song.song` and the old `Song.env` are gone. `Player.restart` runs `InitChannel` with `Player.channels()`, which `Player.start` uses too, and `Song.chans` and `Song.channels` are gone. The sentinels have names: `Song.slice()` for the 100 ms cap, `Song.never()` for the time past the heap's end, `Midi.no_limit()` for a MUS delay's byte count, and `Midi.most()` for the event walks, which were 2^32 - 1 and 98304. `Midi.mus.index` takes the match as a parameter and stops there.

Of the judgement calls, three are done. The MUS reader carries `last`, `chans` and `vels` as one `Midi.Mus.State`, matched once in `Midi.mus.after`, which drops two parameters from each of eleven defs. `Opl.spill.one` takes the chip whole. `tools/wad.nu` reads its variable-length numbers with one `vlq`, and its counts for both WADs are unchanged. Two I left. `Track`, `Mus` and `Bad` are matched four times, but every way I found to merge them trades a constructor match for a Bool match and saves no branch. The event walkers return different things in different programs: a track in `src/midi.bend`, a tally in the test and an event list in `LAWS.bend`. Sharing one would move a test-only list builder into `src/` and rewrite `mus_events`' text for no branch saved. This fix adds a fourth, `Midi.span`, which replaces the walk `Midi.faults` made through `Midi.end`.

The U32 schedule. `ScheduleTrack` computes a callback's time in 64 bits. The render's are U32 microseconds, so a delay past about 600,000 MUS ticks wrapped. I chose to refuse rather than carry 64 bits. Carrying them would change every time in the heap, the rescale and the cut, all of which the captures pin, to serve songs no WAD of ours has. `Midi.span` walks each track to its end for its length in ticks and the largest tempo it sets. The reader refuses a song whose longest track, at the song's largest tempo, could pass 2^31 microseconds, about 35 minutes a pass, with the message `a song whose ticks at its fastest tempo pass the 2^31 microseconds the render counts`. The bound leaves room for two passes. This changes behaviour on purpose, so `song_faults` changes with it. A MUS delay of 2^28 - 1 ticks is now refused, a delay of 300,000 ticks passes, and a 98,305-byte MUS lump of 49,144 releases is refused. Built as WADs beside Freedoom's GENMIDI, the first and last exit 1 with their message and write nothing, and the 300,000-tick song starts rendering.

The speed. perf on the render shows 95% of the cycles in `Opl.mix` and the runtime's `spin_*` loops under it. The song loop and the write each stay under 2%. One shape cost did turn up. `U32.to_nat(65536)` was built for every cut, about 7000 times a pass. With the fuel cut to 1024, a no-IO copy of the loop ran a shareware pass in 8.3 s instead of 9.35 s. `Song.turn` builds its fuel once a buffer. The rest of the gap to ticket 04's 6.8 s is not in the loop. Builds of the same chip code differ by more than that from program to program. My no-IO build ran slower than the shipped render with its writes, and `tools/render.bend` as it stood before 03194f7 printed for over four minutes on the shareware WAD before I stopped it. Three paired runs on Freedoom, `time ./music --threads 1` in a scratch directory, took 25.07, 26.59 and 27.71 s before and 24.20, 25.06 and 25.38 s after. On the shareware WAD, 18.14, 18.85 and 20.48 s before and 17.93, 19.40 and 19.12 s after. The loop's change is inside the noise.

The output did not move. Freedoom's first.raw and second.raw hash to 53300d93…0f79 and fa584f30…9162 before and after, as `nix build .#music` gave. The shareware render hashes to a7c4df38…530f and 649d0fb1…1060 before and after. `bend PROOF.bend` checks all terms, and a flipped `song_faults` entry fails it. `tests/music.bend` passes on both lanes and prints ticket 04's shareware counts by hand. `nix flake check` is green.

Commands:

    bend music.bend -o music; time ./music --threads 1                   (both WADs, before and after, in scratch dirs)
    sha256sum first.raw second.raw
    perf record -F 299 -g ./music --threads 1; perf report --no-children
    bend PROOF.bend
    bend tests/music.bend -o music; ./music; bend tests/music.bend -o music.js; bun music.js
    nix flake check
