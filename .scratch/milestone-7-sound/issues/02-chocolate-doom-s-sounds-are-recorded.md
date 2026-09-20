# 02: Chocolate Doom's sounds are recorded

**What to build:** `tools/listen.nu` records the sound effects Chocolate Doom plays for a demo, with no window, desktop or sound card, as it already records the music. It finds each sound's first frame in the recording. This gives every later audio ticket its outside answer.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] The tool plays a command script as a demo through SDL's disk audio driver in real time, music off by default and on by a flag, at Chocolate Doom's default sound settings
- [x] It reports the frame at which each sound starts, and the ticket records how far the same demo's starts move between two runs
- [x] A recording of one use grunt, of a door heard from one side, and of a sound over the music are taken on Freedoom and described in the ticket: length, peak, left against right
- [x] The ticket lists the sample rate and length of every sound lump in both WADs, read in nushell, and which expansion path of Chocolate Doom each rate takes
- [x] The ticket records the SDL and SDL_mixer versions the dev shell's Chocolate Doom links, since the resampler is theirs
- [x] Nothing here runs in the flake check or opens a device on the desktop

## Comments

19 Sep 2026. Every number below is from the dev shell's Chocolate Doom 3.1.1 on Freedoom 0.13.0, in real time, `SDL_AUDIO_DISK_TIMESCALE=1`. The recordings stay out of the repo. The commands regenerate them, and `--keep` prints where the capture is.

### The tool

    tools/listen.nu sounds x y angle "script" [--things ...] [--music] [--against song.raw] [--keep]
    tools/listen.nu starts capture.raw [--against song.raw]

`sounds` takes a place and a script as `tools/oracle.nu` does. The demo builder and the IWAD copy moved to `tools/demo.nu`, which both tools source. The oracle appends its pause tic and its idle minute as two more runs, so `demo` is the header, the tics and the end byte. The oracle still gives 0 differing pixels on milestone 4's half-open door, `832 384 90` with `20,0,0,0,0 20,25,0,0,0 1,0,0,0,1 20,0,0,0,0`.

Chocolate Doom runs on SDL's dummy video driver, so there is no X server at all, and the disk audio driver writes `capture.raw`, signed 16-bit stereo at 44100 Hz. The tool checks the format the driver logs. `-nomusic` is passed unless `--music` is given. The demo's end ends the capture: under `-playdemo` Chocolate Doom quits when it reads the 0x80. `timeout` is only the guard, a minute past the script's length, and the tool fails if it fires. A script has to idle at its end for as long as its last sound lasts, or the quit cuts the sound.

The scratch config names the defaults: `snd_sfxdevice 3`, `snd_musicdevice 3`, `sfx_volume 8`, `music_volume 8`, `snd_channels 8`, `snd_samplerate 44100`, `snd_maxslicetime_ms 28`, `snd_pitchshift 0`, `use_libsamplerate 0`, `snd_dmxoption ""`. I checked them against Chocolate Doom itself. Run on an empty config, it writes those same values back when it quits. The config also sets `show_endoom 0`. With the default, Chocolate Doom shows the ENDOOM screen after the demo and waits for a key, so the first run sat until the timeout.

`starts` finds the sounds in a kept capture. A sound is a run of frames that differ from the reference, ended by 1024 frames that agree. The reference is silence, or with `--against` a capture of the song alone. Each row has the first frame, how far that is into its 1024-frame buffer, the frames, and the largest left and right difference. `sounds` prints the same table after recording.

The music mode still works. `tools/listen.nu --length 5sec --keep` gave lead 4536, and the FNV-1a hash of its first 72000 frames is 1145462143, the value `tests/music.bend` expects. This was a 7 second run, not the full 270 second one. `render` was not rerun. Its code is unchanged.

### Starts between runs

With sound effects on, the device asks for 1024 frames at a time, `GetSliceSize` for 28 ms. The music alone gets 4096, because the OPL module opens the device with its own 100 ms limit when no sound module did. Every start found was on a buffer's first frame, `into_buffer` 0, in all 30 runs whose sounds were found.

On a quiet machine the starts did not move at all. The grunt started at frame 118784 in 13 runs of 13, 8 of them four at a time. The door demo gave 118784, 144384 and 412672 in 7 runs of 7. With 16 busy loops on the 12 threads and three captures side by side, the grunt started at 119808, 119808, 120832, 120832, 121856 and 123904, so 1 to 5 buffers late, up to 5120 frames or 116 ms. The capture's length moves by a buffer or two even when the starts hold.

The samples do not move. Two grunt captures, one quiet and one under load, are identical from their first sample on over 38912 frames, by `tools/listen.nu compare`. Two door captures are identical over 382976 frames.

The spec expected a buffer of movement between any two runs. On this machine it takes load to see it. The comparison should still take starts from the recording.

### The three recordings

**One use grunt.** `tools/listen.nu sounds -480 192 180 "20,0,0,0,0 1,0,0,0,1 30,0,0,0,0" --keep`. The player stands 32 units from the one-sided wall at x -512, line 829, west of Freedoom's start, and uses it on tic 21. The capture is 157696 frames, 3.58 s. One sound, DSNOWAY: start 118784, 16996 frames, peak left 7399, right 7517. DSNOWAY plays 8498 samples at 22050 Hz, so 16996 is twice that with nothing added or dropped at either end. Left and right differ on 13824 frames. A centred sound is not equal on both sides: `I_SDL_UpdateSoundParams` gives volume 64 and separation 128 a left of 126 * 64 / 127 = 63 and a right of 128 * 64 / 127 = 64, out of 255. The first frames are 63 64, 49 50, 0 0, -50 -50, -63 -64.

**A door heard from one side.** `tools/listen.nu sounds 832 384 90 "20,0,0,0,0 20,25,0,0,0 1,0,0,0,1 70,0,0,0,0 1,0,0,-64,0 210,0,0,0,0" --keep`. Milestone 4's first door: walk up, use it on tic 41, turn 90 degrees right 71 tics later, and wait for it to close. The capture is 501760 frames, 11.38 s, and left and right differ on 152365 frames. Three sounds:

| start | frames | left | right | what |
|---|---|---|---|---|
| 118784 | 8692 | 5019 | 5099 | DSITEMUP, a pickup on the first tic of the walk, centred. 2173 samples at 11025 Hz, times 4 |
| 144384 | 72678 | 7967 | 8352 | DSDOROPN, the door ahead. 36339 samples at 22050 Hz, times 2 |
| 412672 | 73232 | 14263 | 2056 | DSDORCLS, the door now on the left. 36619 samples times 2 is 73238, so the last 6 frames are zeros |

The close starts 268288 frames after the open, 212.9 tics. I did not plan the pickup. It is in the way of the walk, and it shows the 1024-frame gap telling two sounds apart.

**A sound over the music.** First the song alone, `tools/listen.nu sounds -480 192 180 "80,0,0,0,0" --music --keep`, then the grunt over it, `tools/listen.nu sounds -480 192 180 "20,0,0,0,0 1,0,0,0,1 59,0,0,0,0" --music --against <the song's capture> --keep`. The mix is 188416 frames, 4.27 s, peak 8592. The song alone peaks at 4371. The song's first sample is at frame 46105. One sound: start 115712, 16996 frames, left 7399, right 7517, the same in 4 runs of 4. The mix less the song equals the grunt recorded alone on all 33992 samples, so here the mix is a plain sum. With the music on, the grunt lands 3 buffers earlier than without.

The song is the awkward part. Its samples depend on the frame it starts at. 11 of 12 song starts were at frame 46105, and one was at 45080, a buffer and a frame earlier. That capture differs from the others on every sample, and its peaks are 4321 and 4385 against 4345 and 4371. So the tool refuses a reference whose first sample is on another frame than the capture's, and says to record one of them again. With equal starts the song is identical between runs, which is what makes the subtraction work.

### Sound lumps

`open --raw $wad | sound-lumps` in `tools/wad.nu` reads every DS lump as `CacheSFX` does. It gives the rate, the samples played, which is the header's length less the 16 bytes skipped at each end, whether `CacheSFX` takes the lump, and the path. Every lump in both WADs is format 3 with a length that fits, so all are played. The path is `ExpandSoundData_SDL`'s test. A rate that reaches 44100 by a power of two goes through `SDL_BuildAudioCVT` and `SDL_ConvertAudio`. Any other rate goes through Chocolate Doom's nearest-sample loop and its low-pass filter. Names are without the DS, and the number is the samples played.

Freedoom 0.13.0, 69 lumps:

- 22050 Hz, SDL, 44 lumps: PISTOL 10994, SAWUP 17468, SAWIDL 20254, SAWFUL 10146, SAWHIT 4871, FIRSHT 43977, FIRXPL 22473, PSTART 26460, PSTOP 24261, DOROPN 36339, DORCLS 36619, SWTCHN 17971, SWTCHX 8497, PLPAIN 17824, DMPAIN 19030, SLOP 23868, OOF 7843, TELEPT 23644, POSIT1 31397, POSIT2 18893, POSIT3 18816, SGTSIT 23728, SGTATK 19976, CLAW 9603, PODTH1 37084, PODTH2 16199, PODTH3 17460, SGTDTH 32598, POSACT 31008, DMACT 31024, NOWAY 8498, BAREXP 22426, PUNCH 5279, TINK 2599, BDOPN 18496, BDCLS 16096, ITMBK 15532, PLASMA 28536, CACSIT 26639, CACDTH 26281, SKLDTH 8498, CYBDTH 55691, OUCH 10442, JUMP 5995
- 11025 Hz, SDL, 22 lumps: SHOTGN 11159, SGCOCK 5076, RXPLOD 43515, STNMOV 2933, POPAIN 4576, ITEMUP 2173, WPNUP 5700, BGSIT1 8522, BGSIT2 10291, PLDETH 8241, PDIEHI 8869, BGDTH1 9265, BGDTH2 8683, BRSDTH 19360, BGACT 10656, GETPOW 4480, BFG 38267, CYBSIT 51808, SPISIT 39803, SKLATK 11134, SPIDTH 34765, METAL 8039
- 44100 Hz, SDL with no rate change, 1 lump: BRSSIT 110448
- 16000 Hz, nearest sample and low-pass, 1 lump: RLAUNC 19619
- 17990 Hz, nearest sample and low-pass, 1 lump: HOOF 13960

DOOM1.WAD 1.9, 55 lumps:

- 11025 Hz, SDL, 54 lumps: PISTOL 5629, SHOTGN 9413, SGCOCK 5866, SAWUP 16257, SAWIDL 7499, SAWFUL 18064, SAWHIT 7978, RLAUNC 15451, RXPLOD 14443, FIRSHT 14708, FIRXPL 11661, PSTART 8196, PSTOP 6626, DOROPN 13784, DORCLS 13850, STNMOV 2927, SWTCHN 6223, SWTCHX 5371, PLPAIN 15120, DMPAIN 9479, POPAIN 8603, SLOP 11086, ITEMUP 2231, WPNUP 5843, OOF 3878, TELEPT 15452, POSIT1 5302, POSIT2 11246, POSIT3 11063, BGSIT1 13594, BGSIT2 16043, SGTSIT 11132, BRSSIT 13730, SGTATK 9318, CLAW 6372, PLDETH 10980, PDIEHI 10803, PODTH1 12931, PODTH2 9302, PODTH3 10914, BGDTH1 7089, BGDTH2 9279, SGTDTH 12219, BRSDTH 11003, POSACT 10742, BGACT 9992, DMACT 11817, NOWAY 3878, BAREXP 18560, PUNCH 2464, TINK 165, BDOPN 4149, BDCLS 4163, GETPOW 7896
- 22050 Hz, SDL, 1 lump: ITMBK 11143

The spec has every sound either E1M1 can start on the SDL path. That holds for a single player. The two nearest-sample lumps are Freedoom's rocket launcher and the cyberdemon's hoof. Freedoom's E1M1 has two launchers, records 71 and 226, both flagged multiplayer only, and no cyberdemon. TINK in the shareware WAD plays 165 samples, the shortest by far.

### SDL versions

From `ldd` on the dev shell's `chocolate-doom` and `nix-store -qR` on its store path:

- SDL2_mixer 2.8.2
- sdl2-compat 2.32.70 as `libSDL2-2.0.so.0`, over SDL3 3.4.14
- libsamplerate 0.2.2, linked but unused at `use_libsamplerate 0`

This matters for ticket 03. There is no SDL2 resampler in this build. sdl2-compat's `SDL_ConvertAudio`, in `src/sdl2_compat.c`, makes an SDL3 audio stream from unsigned 8-bit mono at the lump's rate to signed 16-bit stereo at 44100, puts the whole sound in, flushes it and reads it back. So the resampler to port is SDL 3.4.14's `src/audio/SDL_audioresample.c`, with the stream's handling of the sound's two ends, and not SDL2's `SDL_audiocvt.c`. The spec's line about SDL's converter is right about the shape, a windowed sinc in float, but the source to read is SDL3's. The recording already says one thing about the ends. A 22050 Hz sound comes out at twice its samples, starting on its first sample at full value.

Two notes for ticket 05. The song is not music in SDL_mixer's sense. `opl_sdl.c` registers it as a post-mix effect, so SDL_mixer mixes the channels first and the OPL callback then adds the song with `SDL_MixAudioFormat` at full volume, which in this build is SDL3's mix. And the panning is `Mix_SetPanning` with the 63 and 64 above.

### Left open

- Two sounds that overlap, or that start less than 1024 frames after another ends, come out as one row. The later capture cases, two overlapping sounds, the ninth sound and the cut sound, need more than this. The way I would go: ticket 05 subtracts its own mix of the sounds found so far and looks for where the rest begins, since every start is on a multiple of 1024.
- A sound with more than 1024 zero frames inside it would come out as two rows. None of the three recordings has one.
- The shareware WAD was not recorded. The ticket asks for Freedoom. `--wad` takes it.
- The demo header says no monsters, as the oracle's does. Milestone 6's fight sounds will need a header that lets them spawn.
