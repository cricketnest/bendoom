# 06: The game plays the music

**What to build:** The game streams its package's render to `Audio`. It opens `Audio` at 44100 Hz when its loop starts. Each frame a write of no samples reads the queue, and the game reads enough frames from the current file to bring the queue to 3072 frames, each left and right sample an F32 over 32768. It plays the first pass once, then the second pass forever by opening it again at its end. The wrapper defaults `BENDOOM_MUSIC` beside `BENDOOM_IWAD`, and the dev shell sets it to Freedoom's render. A missing device or missing files leave the game silent with one line on stderr. The music keeps playing through the level's end and a restart, and quitting closes the device and the file.

**Blocked by:** 05 (The repeat and the render node)

**Status:** done

- [x] `tests/stream.bend` streams the Freedoom render in pieces of varying frame counts on both lanes and prints the samples at the start, on either side of the first-pass boundary and on either side of the second pass's wrap, with expected values read from the files in nushell
- [x] `nix/tests.nix` gets the Freedoom render and sets `BENDOOM_MUSIC`
- [x] No law over a position: the open file is the song's place, so there is none to drift (review, below)
- [x] F32 appears only where samples go to `Audio.write`
- [x] No automated check opens a sound device
- [x] Both packages play their song on the dev machine, heard through at least one repeat

## Comments

19 Sep 2026. An x86_64 benchmark host on AC power, balanced profile.

What landed. `src/stream.bend` is the game's music: the render's two files streamed to `Audio` a frame of the loop at a time. The module's name is the job, since `music.bend` and `src/song.bend` are the render's. `Stream.open` reads `BENDOOM_MUSIC`, opens the device at 44100 Hz and first.raw, and answers nothing after one line on stderr if the variable, the device or the file is missing. `Stream.frame` writes no samples to read the queue, pulls what brings it to 3072 of the ring's 4096 frames (70 ms, so the ring runs dry below 14 frames a second), and writes those. `Stream.pull` answers the bytes read, and `Stream.samples` turns them into the device's samples directly; F32 appears in `Stream.sample` and `Stream.samples` alone, which feed `Audio.write` and nothing else. A sample is its 16 bits with the sign bit flipped, less 32768, over 32768, the same trick `Demo.signed` uses on a byte.

Base has no seek, so the pass's end is a read shorter than asked: the open file closes, second.raw opens again, and the frames already read are written. The next frame reads the new pass. One pull of a game frame is therefore short of the top-up once per pass, which the queue's 70 ms covers. A failed read reads as a read of no frames, which is the same path.

The music lives in the `Game` record beside the demo, as the spec asks. `Game.tick` tops the queue up before the frame's events and tics, `Game.start.go` opens the device with the loop, and `Game.step`'s quit branch closes the device and the file. The loop's other end, the fuel the window bench gives it, ran off without closing anything, so `Game.shut` now closes the window, the demo and the song there too. A restart after the exit rebuilds the state and leaves the record's music alone, so the song plays on, as `S_ChangeMusic` does when it is asked for the song already playing.

Review. `Stream.At` counted the song's place one frame at a time, up to 3072 steps a frame, so that a law could prove two reads land where their sum does. Nothing read that count: the pass switch is the short read, and the open file is the place. The count, `Stream.one`, `Stream.took`, `Stream.after` and the laws `stream_pieces` and `stream_passes` are deleted, the spec says why, and the test no longer prints a place: an empty read after each pass's last three frames shows the pass ends where the file does. `Stream.frames` packed each four bytes into a word that `Stream.samples` then split again; the samples now come from the bytes. The type's constructor is `Stream`, not `Music`.

The test. `tests/stream.bend` opens the render with `Stream.tape`, which is the tape without a device, so no automated check opens a sound device. It reads 3 frames, spans the rest of the first pass in pieces of 1, 7, 100, 2048, 33, 999, 3072, 5 and then 3072, and prints the frames at the song's start, at each pass's last frames, at the pull that finds the end, and at each start after one. Every expected value was read from the files in nushell before the Bend code answered, and `od -A d -t d2` confirmed the two boundaries. first.raw's last three frames are (268, 286), (249, 264), (233, 247) and second.raw's first three are (216, 229), (204, 215), (196, 204), so the tails carry over as ticket 05 measured; second.raw's last three are (167, 186), (159, 179), (156, 172), and the wrap replays its first three. Native 0.39 s, bun 2.1 s for the 46 MB.

A probe first measured what streaming costs, since a test that reads both passes on the JS lane could have been too slow for the flake check: 23 MB in pieces of 3072 frames takes 0.115 s native and 1.0 s on bun. Pieces of 16384 frames overflow bun's stack in `List.length`, so a piece stays at or under the 3072 a game frame asks for. The 40 s a first probe took was its own fuel spinning on empty reads past the end, not the reading.

Packaging. `nix/bendoom.nix` takes the `music` function and applies it to its own IWAD, so `bendoom-shareware` gets the shareware render, and the wrapper defaults `BENDOOM_MUSIC` beside `BENDOOM_IWAD`. `nix build .#bendoom .#bendoom-shareware` built both; the Freedoom wrapper points at 23,039,532 and 23,039,552 bytes, the shareware one at a render of its own, 16,937,696 and 16,937,532 bytes (4,234,424 and 4,234,383 frames). The dev shell and `nix/tests.nix` get Freedoom's. `nix/tests.nix` also needed alsa-lib in `buildInputs`: tests/game.bend builds the game's loop, whose music compiles the Audio effect. `nix/film.nix` is ticket 07's.

Checks run. The full `nix flake check` passes, both lanes and every proof; the tests log shows PASS stream and PASS game on native and js. The game was not played through the speakers from an automated check: the window bench ran on Xvfb with `ALSA_CONFIG_PATH` naming a config whose only default is the null device, which fails closed, since a config that does not load leaves `Audio.open` failing and the game silent. 600 frames came out at 27 frames a second there, against 29 with the music absent, with a nix build running beside it; the null device drains the ring as fast as it is filled, so the game reads the full 3072 frames every frame and the pump thread spins, which is the worst case and not the number ticket 08 wants. Both silent paths printed their one line: "BENDOOM_MUSIC names no render" with the variable unset, "no sound device" with it naming nothing (the device would not open in that shell at all, which is why nothing reached the speakers).

Left for the maintainer: both packages played and heard through at least one repeat. That box stays unticked.

Commands:

    git worktree add ../bendoom-m8-06 -b m8-06-game-music 8a25616
    nix build .#music
    nix develop -c bend tests/stream.bend -o stream; BENDOOM_MUSIC=... ./stream --threads 1
    nix develop -c bend PROOF.bend
    nix build .#bendoom .#bendoom-shareware
    nix flake check

For ticket 08:

- The bench counts no empty queues yet. `Stream.frame` reads the queue in `Stream.topped` and throws the count away; that is where the count the bench reports comes from, and it will have to travel out of `Game.loop` with the frame rate.
- `Stream.top()` is the one place the 3072 lives.
- The music render's derivation takes all of `src/`, so any change to the game's sources rebuilds it. Not this ticket's to fix, but it costs 25 s on every touched source.

19 Sep 2026. The maintainer played both packages with sound, heard each song through a repeat, and compared them by ear with recordings of the songs on OPL hardware. Milestone 8 is done.
