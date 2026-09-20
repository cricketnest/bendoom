# 05: The mixer plays a sound over the song

**What to build:** The music stream becomes the mixer and stays the only writer to `Audio`. Given the song and a list of hand-written events (this sound, from this frame, at these left and right volumes), it streams each playing sound from its file, adds it to the song with SDL_mixer's arithmetic and clipping, and produces the frames the device would get. No channel logic yet.

**Blocked by:** 04 (The sounds node)

**Status:** ready-for-human

- [x] Each playing sound is read from its file front to back, and nothing but the frames about to be written is held
- [x] Volumes scale and sums clip as SDL_mixer's do, at Chocolate Doom's default music and sound volumes
- [x] With no sound playing the output equals the song alone, and milestone 8's stream test keeps its values
- [x] A test on both lanes mixes Freedoom's sounds and song in pieces of varying frame counts and prints a hash and sampled values at each sound's start and end and where two overlap, with expected values read from the recordings in nushell
- [ ] `tools/listen.nu` compares three recordings with the mixer's output placed at the recorded starts: one centred sound, two overlapping, one over the music; the ticket records differing samples and the largest difference, target zero
- [x] The old stream's code that the mixer replaces is deleted, not kept beside it

## Deferred to the later pass

- The three recordings through `tools/listen.nu` and the count of differing samples, the unticked box above. What stands in for it tonight is the grunt over silence, whose hash and frames are the ones ticket 03 took from Chocolate Doom's capture and from its own `Mix_Chunk` under gdb.
- The `song` line of `tests/mixer.bend`, the song with two sounds over it, is a regression pin and not a recording's value. The recording comparison above is what would settle it.

## Comments

20 Sep 2026.

### What was built

- `src/stream.bend` is the mixer. `Stream.window(want, tape, chans)` is the whole seam: it reads the song's next frames (silence when there is no render), then folds every playing channel over them, and answers the tape, the channels and the frames. `Stream.frame` is that window between the two writes to `Audio` that read the queue and fill it. Nothing else writes to the device.
- The frames travel as one word a frame, the left sample in the low half and the right in the high, which is what the mix adds to and what `Stream.samples` turns into what `Audio.write` takes. `Stream.words` makes them from the song's bytes. The old `Stream.samples`, which went from bytes straight to floats, is gone.
- `Stream.side` is SDL_mixer 2.8.2's `_Eff_position_s16lsb` on one side, `(Sint16) ((float) sample * (side / 255.0f))` truncated toward zero. `Stream.add` is SDL 3.4.14's `SDL_MixAudio` at volume 128, which `ADJUST_VOLUME` leaves as `sample * 128 / 128`: an integer sum clipped to `SDL_MIN_SINT16` and `SDL_MAX_SINT16`. Both sign bits are flipped so the sum runs in 0 to 131070 and the clamp is `U32.clamp`, since a U32 has no room below zero.
- Channels are added one at a time in slot order, since `mix_channels` in SDL_mixer's `mixer.c` writes the music first and then calls `SDL_MixAudioFormat` once a channel, so the clipping of one addition is what the next adds to.
- A channel's file is read `want * 2` bytes a frame of the loop and nothing is held but the frames going out. A read that comes up short is the sound's end: the file closes and the channel frees itself, the same way `Stream.pull` finds the end of a pass.
- The channels are asked for as many frames as the song gave, not for the whole top-up, so that the short read at a pass's end (three frames, once every 2.2 minutes) costs a playing sound nothing.
- The mixer now holds the sounds directory and a `Maybe` of the song's tape, so the three empty cases each say one line and play what is left: no device (silent), no render with sounds (the sounds alone), no render and no sounds (silent, the device let go), no sounds directory (the music alone).
- `tests/sfx.bend` lost its own copy of the side scaling and calls `Stream.side`, which ticket 03's comment asked for. Its values did not move, so the mixer's scaling is now what that test checks against Chocolate Doom.

### Where each expected value came from

- `tests/mixer.bend`'s `grunt` line is DSNOWAY started centred at the default volume with no song under it, read in windows of 1, 7, 100, 2048, 33, 999, 3072, 5 and then 3072 frames. Its hash, 3631499139, and its frames 0, 1, 3, 2714 and 16995 are `tests/sfx.bend`'s `heard` values for the same sound, which ticket 03 read from `tools/listen.nu`'s capture of Chocolate Doom and checked against Chocolate Doom's own `Mix_Chunk` dumped under gdb. They came out equal on the first run of the mixer, so the file reading, the window splitting and the scaling all agree with the original.
- Frame 16996, the one after the sound's last, is 0 0 and the table after the run is empty: the channel freed itself where the file ended.
- The `song` line is a regression pin, said so in the test's header.
- `tests/stream.bend` keeps every value it had, which is the no-channel case.

### Trade-offs

- The mixer holds the channels rather than the game record holding them beside the music. They are still outside the sim's state, which is what the milestone asks, and it keeps one value to thread through the loop and one place that closes the files. A game with no device has no channels at all, which is right: nothing can play.
- With no sounds directory the mixer still tries to open each sound's file and takes the failure as a drop. It costs one failed open a sound and saves a branch, and the line at startup already says what is happening.
