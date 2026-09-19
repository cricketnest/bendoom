# 08: The frame rate holds and milestone 8 closes

**What to build:** Close the milestone: the frame rate holds with the music playing, the comparisons are recorded, the roadmap is truthful, and nothing dead is left behind. Review the complete milestone against the spec and the repo's standards, and fix the findings rather than merely recording them.

**Blocked by:** 04 (The shareware song matches), 06 (The game plays the music), 07 (The film carries the music)

**Status:** ready-for-human

- [x] The window bench plays the music and reports frames a second and the frames whose queue was empty before the write; the target is at least 35 frames a second and no empty queue after the first frame, with the machine and power state recorded
- [x] Every capture comparison from tickets 02 to 05 is zero or has its accepted cause beside it
- [x] The full flake check passes, both lanes and every proof
- [x] A standards and spec review of the milestone is run and every accepted finding is fixed
- [x] The erasure pass deletes dead definitions, stale comments and any scaffolding the tickets left
- [x] The music-from-the-wad ticket is updated with the measured render speed
- [ ] The README marks milestone 8 done, and the spec's status changes to done only after every earlier ticket is complete

## Comments

19 Sep 2026. An x86_64 benchmark host on AC power, `balanced` profile, `powersave` governor with `balance_performance`, Linux, PipeWire 1.6.8.

**The merge.** Milestone 5 came in from main and not from m5-12-close at 6592545. Since the handoff, main has taken m5-12-close through e50c390, where the maintainer played both maps and milestone 5 was marked done, and then the recorder with a fix to the route test. This branch already had the recorder, so merging main brings in milestone 5 plus the merge of the two. The merge is a4e8939, committed alone. Its conflicts:

- `src/level.bend`: milestone 8 moved lump lookup to `Wad.find`, and milestone 5 added THINGS' fifth field (the options) through the old `Level.lump`. `Level.plan` now reads THINGS' five fields through `Wad.find`, and `Level.lump` stays deleted. The sim test's patched map, new in milestone 5, called `Level.lump` too and now calls `W.Wad.find`.
- `docs/bend.md`: milestone 8's rules on `do` blocks and `List.length` and its 4096n literal limit sit beside milestone 5's rules on pairs in cases, Data-only lists and `type` as a keyword. Both sides had described the same `[]` constraint in different words, and they are now one rule.
- `LAWS.bend` and `PROOF.bend`: both sets of imports and laws. The things' proofs come before the music's, as their laws do.
- `tests/render.bend`: it imports both the one FNV-1a (`src/fnv.bend`) and milestone 5's inventory.
- `tools/wad.nu`: the things, the BSP and `sector-at` come before the song's events, and the header names all of them.
- The route test's `Game` gained the music field (a type error, not a textual conflict).

After the merge, `nix flake check` passed: every test native and on bun (demo, game, load, music, ranges, render, route, sim, stream, wad_dir), and "All terms check." `bend PROOF.bend` passed. `nix build .#music` rebuilt the render with the patched Bend, and its bytes did not change: first.raw 53300d93…0f79, second.raw fa584f30…9162.

**The bench.** `Stream.topped` counts the game frames whose top-up found the device's queue empty. The count lives in the `Stream` record beside the device and the tape, and `Stream.stop` answers it. The game loop ends in `Game.shut` whether the game quits or the fuel runs out, and `Game.start` answers the count, or none when the music is silent. `doom.bend` drops it and `bench/window.bend` prints it after the frames a second. The first frame always counts, because nothing has been written yet, so the target reads as a count of 1.

Setup. Xvfb ran on :97 at 1600x1200x24. The sound device was a PipeWire null sink, `pactl load-module module-null-sink sink_name=bendoom_null rate=44100 channels=2 format=float32le`, which runs on a timer at the real rate and plays nowhere. The game reached it through `ALSA_CONFIG_PATH`, which named a config holding a single `pcm.!default` of type pipewire, with `playback_node "bendoom_null"` and nixpkgs pipewire 1.6.8's ALSA plugin as its `lib`. Nothing else on the desktop changed: the default sink stayed the laptop's. The first run played a render of zeros. `pw-link` showed `alsa_playback.window` linked to `bendoom_null` and nowhere else, and only then did Freedoom's render play. During a run, `pw-top` listed `alsa_playback.window` as F32LE, 2 channels, 44100 Hz, quantum 220, no errors, under the sink's driver. The graph runs at 48000, so PipeWire resamples. `parec` recorded the sink's monitor at 44100 Hz over one run: 662,382 frames in the 15.0 s it ran, which is the real rate. The song sounds for 471,218 frames (10.69 s) of the run's 10.95 s, with no silent stretch longer than one frame and a peak of 4475. The module was unloaded afterwards.

The scene is milestone 5's key room, the frame-rate bar's own: ticket 12's script, which leaves the player in the blue key room's doorway with 52 sprites in view, the key running its states, the door cycling and the lights blinking. Each run was 600 frames, one thread, `bench/window.bend` built natively from this branch. Load average 1.5 to 1.6:

| music | frames a second | queue empty |
| --- | --- | --- |
| Freedoom's render | 53, 50, 51, 54 | 1 in each run: the first frame |
| absent (`BENDOOM_MUSIC` unset) | 53, 52, 54 | silent |

The 54 with music is the run the monitor recorded. Milestone 5's ticket 12 measured 55, 55, 56 at a load of 1.0. An earlier set ran while a clang build worked beside it (load 5.7): 41, 46, 43 with music and 45, 47, 44 without, and still one empty queue each. The target holds: at least 35 frames a second, and no empty queue after the first frame. Streaming costs about 2 frames a second. Ticket 06 measured 27 frames a second on ALSA's null device, which drains as fast as the game fills it. That number was the null device's cost, not the music's.

**The captures.** Tickets 02 to 05 recorded:

| comparison | frames | differing |
| --- | --- | --- |
| Freedoom's opening (ticket 02) | 9,389 | 0 left, 0 right |
| Freedoom's first pass (ticket 03) | 5,763,979 | 0, 0 |
| Freedoom's both passes, against two captures (ticket 05) | 11,523,867 | 0, 0 |
| the shareware first pass (ticket 04) | 4,238,520 | 0, 0 |
| the shareware both passes (this ticket) | 8,472,903 | 0, 0, largest 0 |

No ticket had compared the shareware song's second pass. A new real-time capture with `--length 200sec` has a lead of 4536 and 8,830,976 frames. `tools/listen.nu render` against the idle render (passes of 4,238,520 and 4,234,383 frames) finds no differing sample. After the review fixes below, both WADs render the same bytes: Freedoom's first.raw 53300d93…0f79 and second.raw fa584f30…9162, the shareware ones a7c4df38…530f and 649d0fb1…1060, as ticket 05 gave.

**The review.** Two agents reviewed `git diff main...HEAD`, which after the merge is exactly milestone 8. One read it against AGENTS.md and docs/bend.md, the other against the spec, the tickets and Chocolate Doom's source.

Fixed from the standards review:

- Three comments that were false: PROOF.bend's music laws split because `Midi.drop` matches the list at a count of 0, not because of `List.drop`; LAWS.bend's "a song's division" sat on `Closed.events` and belongs to `Closed.song`; `Midi.fault` also refuses a song too long for the U32 microseconds.
- Four hand-written little-endian 16-bit reads (`Player.flags`, `Player.frequency`, `Midi.mus` and `Stream.samples`) are `Bytes.le16`.
- The 96 KiB limit was two literals, 98303 and 98320. It is now one, `Midi.limit()`, and `Midi.most()` derives from it. The resampler's 908 appeared five times and is now `Opl.ratio()`. Three runs before and after took 22.6 to 22.8 s and 22.8 to 23.6 s for Freedoom's two passes, which is inside the noise.
- `Midi.Op`'s `Finish` and `Refused` ended the score the same way, differing only in whether it was fine. They are one constructor, `Finish{fine}`, with one branch fewer. `Midi.chan`'s one-byte event builds its event through `Midi.chan.two`, as the two-byte one does.
- `Song.clear` opened the chip's frames itself. `Opl.Frames.clear` now sits beside `Frames.out` and `Frames.queue`. `music.bend`'s turn of one buffer was written out twice and is now `Music.turn`. `tools/wad.nu` binds a program change's test once, and a double blank line in opl.bend is gone.
- The count's first shape had quit and running out of fuel end apart. `Game.step`'s quit branch closed the demo and the song, and a copy of Base's `App.next` closed the window and answered no count, so the bench would have printed "silent" for a quit. Now the frame answers whether it quits, `Game.over` sends a quit to `Game.shut` as running out of fuel does, and none means silent only. `Game.step`'s close block, the dropped binding and the use of `App.next` are gone. The game and route tests read the frame's quit flag, and the route test's quit branch, which could not happen, is gone.

Rejected, with the reason:

- **Naming the tags "MThd", "MUS" 0x1A and "MTrk".** The comment above `Midi.file` names each where it is read.
- **Giving a Bad file a division so that `Midi.fits` needs no `U32.max`.** A Bad file's division means nothing. A made-up 1 would state that no better than the guard does, and the guard sits where the division is divided by.
- **`Test.frames`' equal `More` and `Ended` branches.** Each constructor carries the song, and a match must open it to reach the song.
- **One 16-bit printer for the tests.** Tests cannot share a module (milestone 5 found the same). The stream test's printer changed anyway, below.

Fixed from the spec review:

- A missing second.raw killed the game at the first pass's end, when `IO.try` opened it. The spec says a missing music file leaves the game silent with one line. `Stream.tape` now opens second.raw and closes it before it opens first.raw, and a render without either prints "BENDOOM_MUSIC holds no first.raw and second.raw; playing silent". Reopening a pass later still goes through `IO.try`, since a render in the store cannot lose a file.
- The stream test decoded the bytes with its own arithmetic and never ran `Stream.samples`, the F32 conversion the game writes. It now prints each sample as `Audio.write` takes it, turned back into 16 bits: x times 32768, offset by 32768 so that it converts as a Nat. Its lines did not change. A new line pins the bytes 00 80, FF 7F, FF FF and 00 00 as -32768, 32767, -1 and 0, worked by hand.
- Prose made false: the spec's music state (which pass, where the code keeps second.raw's path, and now the count), the spec's pass switch (the short read's frames are written and the next frame reads the new pass), `nix/tests.nix`'s "whose music opens ALSA" (it links ALSA and no test opens it), and `Stream.top`'s "above 14 a second" (3072 frames are 69.7 ms).
- The README's line now says that each package plays the song of the WAD it was built with, which is the one exception to the game reading its WAD at runtime.

Accepted as the spec has it: the film uses its package's render and ignores `BENDOOM_MUSIC`, since the music is a function of the package's IWAD.

**The erasure pass.** Gone:

- the second close path in `Game.step` and the game's use of `App.next`
- the route test's impossible quit branch
- the stream test's own byte decoder
- `Refused{}` and its branch
- `Midi.chan`'s second build of an event
- `Song.clear`'s reach into the chip's frames
- `music.bend`'s duplicated turn
- the 96 KiB limit as two literals, and 908 written five times
- four hand-written 16-bit reads
- the stale comments listed above

A scan of every def in the milestone's files, and in LAWS.bend, counted the calls outside each def's own body and found none unused. `Midi.fault`'s only caller is `song_faults`. No scratch tool was committed: the probes, the ALSA config, the silent render and the captures all stayed in /tmp. `docs/bend.md` and the file headers of song.bend, opl.bend, midi.bend, player.bend, stream.bend, fnv.bend, music.bend, listen.nu, bench/chip.bend and the tests are true of the code. Tickets 02 to 05 name `src/music.bend`, `tools/opening.bend` and `tools/render.bend` as history, and they stay.

**Checks.** After the fixes, `nix flake check` passes: "All terms check.", and all ten tests pass native and on bun. The game and route tests passed natively after the quit change, and the stream test passed on both lanes after its printer changed.

**Left for the maintainer.** Play `bendoom` and `bendoom-shareware` with sound and hear each song through at least one repeat: ticket 06's last box. Then the README's milestone 8 line and the spec's status say done, and this ticket's last box is ticked. Ticket 06 and the spec are ready-for-human for that alone.

Commands:

    git worktree add ../bendoom-m8-08 -b m8-08-close f4c9d76; git merge main
    nix develop -c bend PROOF.bend; nix build .#music; sha256sum first.raw second.raw; nix flake check
    pactl load-module module-null-sink sink_name=bendoom_null rate=44100 channels=2 format=float32le
    Xvfb :97 -screen 0 1600x1200x24
    DISPLAY=:97 ALSA_CONFIG_PATH=asound.conf BENDOOM_MUSIC=<render> SCRIPT="<milestone 5 ticket 12's>" ./window --threads 1
    pw-link -l; pw-top -b -n 2; parec -d bendoom_null.monitor --rate=44100 --format=s16le --channels=2 --raw
    pactl unload-module <module>
    tools/listen.nu --wad <doom1.wad> --length 200sec --keep
    BENDOOM_IWAD=<doom1.wad> tools/listen.nu render <capture> --binary music
    time ./music --threads 1; sha256sum first.raw second.raw                 (both WADs, before and after the fixes)
