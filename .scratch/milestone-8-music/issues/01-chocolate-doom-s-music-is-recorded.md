# 01: Chocolate Doom's music is recorded

**What to build:** The oracle for the whole milestone. `tools/listen.nu` runs Chocolate Doom from nixpkgs on a given WAD, warped to E1M1 with no monsters and no sound effects, at its default music settings, and records its music to a file through SDL's disk audio driver. Nothing opens a window on the desktop. The tool reports, for the capture, whether left equals right and how many silent samples come before the first note. Later tickets extend it to compare a render with the capture.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] The tool records at least two passes of E1M1's song (about 261 s of audio for Freedoom, 192 s for the shareware WAD) and stops Chocolate Doom by itself
- [x] The capture is 44100 Hz signed 16-bit stereo, and the tool checks the format it got rather than assuming it
- [x] The environment names the nixpkgs SDL (sdl2-compat over SDL3) honours for the disk driver, its output file and its speed are found and written in the tool's usage comment
- [x] Music settings match Chocolate Doom's defaults (OPL, 44100 Hz, volume 8, no `snd_dmxoption`) through a scratch config, not the user's
- [x] No window opens on the desktop: the video runs on SDL's dummy driver or on Xvfb, as `tools/oracle.nu` does
- [x] The report gives left-equals-right for the whole capture and the count of silent samples before the first note
- [x] Two captures of the same WAD are compared, and the comments record whether the lead and the samples after it vary between runs
- [x] Both WADs are captured and their numbers recorded in the comments; the shareware run is by hand

## Comments

19 Sep 2026. Chocolate Doom 3.1.1 from the flake's nixpkgs, on sdl2-compat 2.32.70 over SDL3 3.4.14 (not 2.32.72 as the handoff had it). Every capture below is real time, `SDL_AUDIO_DISK_TIMESCALE=1`.

Commands:

    tools/listen.nu --keep
    tools/listen.nu --wad /nix/store/qvks2w06fb8kg6c4jazpnbc2przpm49x-doom1-wad-1.9/share/games/doom/doom1.wad --length 200sec --keep
    tools/listen.nu compare <first capture> <second capture>

Each was run twice. Both runs of a WAD went side by side, and the shareware runs went beside the Freedoom ones.

Freedoom (`freedoom1.wad` 0.13.0): the driver wrote S16LE, 2 channels, 44100 Hz, as the tool checked. The first sample other than zero is frame 4536 in both runs. The two captures, aligned at that frame, are identical over the 11,910,728 frames they share: 0 differing samples, largest difference 0. Left and right differ on 11,830,672 of 11,943,936 frames. The song repeats 5,759,882 frames (130.61 s) after the first note, found by matching the left channel 20 s into each pass, so the 270 s default holds two passes and 8.8 s more.

Shareware (`DOOM1.WAD` 1.9, by hand): S16LE, 2 channels, 44100 Hz. The lead is 4536 in both runs as well, and the two captures are identical over their 8,838,728 shared frames. Left and right differ on 7,104,942 of 8,843,264 frames. The song repeats 4,234,429 frames (96.019 s) after the first note, so 200 s holds two passes. That is 609 frames (about 14 ms) longer than the written 13440 ticks at 140 Hz plus the 5 ms restart. The likely cause is each callback running on the first whole sample at or after its time, with the track's next event scheduled from there. This is one more reason the render must take the loop point from its own restart, as the spec says.

Left does not equal right. That breaks the spec's premise that in OPL2 mode "the chip computes one channel". Nuked OPL3 1.8, as Chocolate Doom ships it in `opl/opl3.c`, returns in `OPL3_Generate` the right sample the previous call mixed (`buf[1] = mixbuff[1]` at its top). The left is mixed partway through the current sample: after slots 0 to 14 are updated but before slots 15 to 17, which are the carriers of voices 6 to 8. Both then go through the resampler. In the first second of Freedoom's song, |L − R| reaches 1823 against a peak of 3723, and right is not left delayed by a whole sample either. A bit-exact render has to produce both mixes, so the render files, the game's writes and the capture comparison are stereo, not mono. That is the spec's call to change, and ticket 02 is the first it affects.

The lead is stable. In real time it was 4536 in all 13 runs that reached the song: the 4 above, 5 of 6 run in parallel, and 4 short ones. That is one 4096-frame buffer (Chocolate Doom's slice size at 44100 Hz, as ticket 02 found) plus 440 frames, the same for both songs. A render that runs the chip idle before the song needs to know how much of the 4536 is idle chip and how much is the song's opening and the note's attack. That is ticket 02's question.

Faster than real time: `SDL_AUDIO_DISK_TIMESCALE=0` wrote about 283 s of audio in 6 s. Its music is timed by samples, as `AdvanceTime` reads: in a fast capture Freedoom's pass is 5,759,881 frames, a frame from the real-time one, and fast runs with the same lead are identical over 7.8 million frames. But the lead moves: 24650 or 28746, which is 24 or 28 buffers plus 74, where real time lands on four plus 440. Its samples then differ from the real-time capture's from the first note on. Resampler phase and the chip's timers alone would explain that. The other possible cause is that `I_OPL_PlaySong` schedules each track with no `OPL_Lock` while the fast audio thread keeps running beside it. The tool stays at real time, where the audio thread sleeps between buffers as it does in play.

Environment names: SDL3's `SDL_AUDIO_DRIVER=disk`, `SDL_AUDIO_DISK_OUTPUT_FILE` and `SDL_AUDIO_DISK_TIMESCALE` all work. SDL2's `SDL_AUDIODRIVER` and `SDL_DISKAUDIOFILE` work too, through SDL3's fallback and sdl2-compat's mapping, but `SDL_DISKAUDIODELAY` is ignored. The disk driver logs the format it opened on stderr, and the tool reads that line. Video runs on SDL's dummy driver, so no X server is needed.

Found on the way: Chocolate Doom writes the song to `$TMPDIR/doom.mid` before playing it. Among the parallel runs, one read another's half-written file ("I_OPL_RegisterSong: Failed to load MID") and stayed silent. The tool now sets `TMPDIR` to its scratch dir, and it fails if no note comes within the first 10 s.
