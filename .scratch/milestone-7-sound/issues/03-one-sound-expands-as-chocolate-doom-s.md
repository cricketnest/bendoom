# 03: One sound expands as Chocolate Doom's

**What to build:** A Bend program reads a sound lump as Chocolate Doom's `CacheSFX` does and expands it to 44100 Hz by the path that lump's rate takes. One expanded sound is compared with ticket 02's recording. This is the risky step of the milestone, so it ends with numbers for the maintainer.

**Blocked by:** 02 (Chocolate Doom's sounds are recorded)

**Status:** resolved

- [x] The lump reader checks the header, takes the rate and length, refuses what Chocolate Doom refuses, and drops the padding it drops
- [x] The expansion follows the converter Chocolate Doom really runs for 11025 and 22050 Hz, which ticket 02 found to be SDL3 3.4.14's audio stream and resampler under sdl2-compat; the nearest-sample loop serves only two Freedoom sounds E1M1 never starts, so it is not written
- [x] If SDL's filter table is needed, a nushell tool generates it from SDL's source, as the angle and chip tables are generated
- [x] The use grunt, expanded and scaled to the recording's volume, is compared with the recording from its first frame: the ticket records the count of differing samples and the largest difference, target zero
- [x] If zero is out of reach, the ticket stops and brings the numbers to the maintainer before ticket 04 starts
- [x] The ticket records how long expanding every sound of Freedoom takes on the dev machine, native, so that the build-time decision in the spec rests on a number
- [x] A test on both lanes expands one Freedoom sound and prints a hash and sampled values read from the recording in nushell

## Comments

19 Sep 2026. Chocolate Doom 3.1.1 from the flake's nixpkgs on Freedoom 0.13.0, on an x86_64 benchmark host on AC power, balanced profile. Three other agents were building in sibling worktrees, so the load average was near 4 during the timing. The recordings and scratch programs stay out of the repo.

### The numbers

The use grunt, DSNOWAY, expanded by `src/sfx.bend` and scaled to the recording's volume, against `tools/listen.nu sounds -480 192 180 "20,0,0,0,0 1,0,0,0,1 30,0,0,0,0" --keep` from frame 118784: 0 of 33992 samples differ, over 16996 frames, left and right. The largest difference is 0.

Three more sounds from ticket 02's door recording, the same way: DSITEMUP at 11025 Hz from frame 118784 at left 63 and right 64, 0 of 17384 samples differ. DSDOROPN from 144384 at 62 and 65, 0 of 145356. DSDORCLS from 412672 at 111 and 16, 0 of 146476. Both doors reach -32768, so the clamp is exercised.

The recording is a weak judge of the last bit, since a centred sound is scaled by about a quarter before it is written. So I also read Chocolate Doom's own chunks. gdb on the same headless run breaks on `Mix_PlayChannelTimed`, whose second argument is the `Mix_Chunk`, and dumps `abuf` for `alen` bytes. That is the expansion at full 16 bits, before any volume. All four chunks equal the Bend expansion on every sample: 16996, 8692, 72678 and 73238 frames, 0 differing. Left equals right on every frame of all four.

The gdb script, run with the system's gdb 17.2 in a scratch directory kept by `tools/listen.nu sounds ... --keep`, under the environment `tools/listen.nu` sets (dummy video driver, disk audio driver, so no window and no device):

    set breakpoint pending on
    set $n = 0
    break Mix_PlayChannelTimed
    commands
      silent
      set $abuf = *(unsigned char **)($rsi + 8)
      set $alen = *(unsigned int *)($rsi + 16)
      eval "dump binary memory chunk%d.raw $abuf ($abuf + $alen)", $n
      set $n = $n + 1
      continue
    end
    break Mix_SetPanning
    commands
      silent
      printf "pan left %d right %d\n", $rsi & 255, $rdx & 255
      continue
    end
    run

    gdb -batch -x dump.gdb --args chocolate-doom -iwad freedoom1.wad -playdemo script -config default.cfg -extraconfig chocolate-doom.cfg -nomusic

The `Mix_SetPanning` breakpoint is where the doors' 62 and 65, and 111 and 16, come from.

The scaling is SDL_mixer 2.8.2's `_Eff_position_s16lsb` in `src/effect_position.c`: `(Sint16) ((float) sample * left_f * dist_f)`, with `left_f = (float) left / 255.0f` from `Mix_SetPanning` and `dist_f` 1. The cast truncates toward zero. `mix_channels` in `src/mixer.c` then calls `SDL_MixAudioFormat` with volume 128, which sdl2-compat makes 1.0 and SDL3's `SDL_MixAudio` makes `sample * 128 / 128`, so it adds the sample unchanged. For the comparison I did this in nushell, with each float operation rounded to single precision. `tests/sfx.bend` does the same in Bend for its "heard" lines. Ticket 05's mixer owns this arithmetic, and the test should call the mixer's once it exists.

### The C path

`CacheSFX` refuses a lump under 8 bytes, a format other than 3, a header length over the lump's size less 8, and a length of 48 or less. It plays the bytes from lump offset 24 for the length less 32. `ExpandSoundData_SDL` gives SDL the sound when `ConvertibleRatio` holds. At 44100 Hz output that is 11025, 22050 and 44100 Hz only, since 11025 is odd. `Sfx.run` gives no run for any other rate.

sdl2-compat's `SDL_ConvertAudio` (`src/sdl2_compat.c`) makes an SDL3 stream from unsigned 8-bit mono to signed 16-bit stereo at 44100, puts the whole sound in, flushes and reads `len * len_mult` bytes back. In SDL 3.4.14's `GetAudioStreamDataInternal` (`src/audio/SDL_audiocvt.c`):

- `SDL_ReadFromAudioQueue` converts the bytes to float with seven frames of padding on each side. Before the sound the padding is the queue's history, which starts as silence. After it, `PeekIntoAudioQueueFuture` fills with silence because the track is flushed. Silence is byte 128, which is 0.0.
- `SDL_Convert_U8_to_F32_SSE2` is `(b - 128) / 128`, exact. The scalar version gives the same.
- `SDL_ResampleAudio` resamples mono, before the channel change, since SDL resamples at the lower channel count. The rate is `ceil(2^32 * src / dst)`, exactly 2^31 or 2^30 here, so the position's fraction is always a whole phase of the filter's eight and the cubic interpolation between phases gets a fraction of 0. Only the constant term of each tap's cubic counts. At phase 0 the taps are 1 and eleven zeros, so every second or fourth frame is the source sample itself. That is ticket 02's "starts on its first sample at full value". The output has `ceil(frames * 2^32 / rate)` frames, exactly 2 or 4 a source sample, with nothing added or dropped.
- The frame function is `ResampleFrame_Generic_SSE`, since x86_64 always has SSE. With one channel it multiplies the twelve taps by the twelve samples as three vectors of four, adds the three vectors, then adds lanes 0 and 1, lanes 2 and 3, and the two sums. `Sfx.sum` adds in that order. The scalar `ResampleFrame_Mono` adds left to right and would differ in the last bit.
- `SDL_ConvertMonoToStereo_SSE` copies each float to both sides. So Chocolate Doom's chunk holds the same sample twice, and the expansion here is mono.
- `SDL_Convert_F32_to_S16_SSE2` adds 257.0f, which rounds to the nearest 1 / 32768 with ties to even, subtracts 257's bits, and `_mm_packs_epi32` clamps. `Sfx.sample` does `((x + 257) - 256) * 32768`, clamped to 0 and 65535, which is that sample plus 32768. The scalar version adds 384 and gives the same values.
- The stream works in chunks of 4096 output frames. Every step is per sample and the resample offset returns to 0 at each chunk's end, so the chunks cannot be seen in the output.

Fused multiply-add: the nixpkgs libSDL3.so.0.4.14 holds none. `objdump -d` on it shows 0 `vfmadd`, `vfnmadd` or `vfmsub` instructions in the whole library. SDL's own `sdl_madd_ps` macro is a separate multiply and add.

### The table

`tools/gen_sfx_taps.nu` writes `src/sfx_taps.bend` and regenerates it byte for byte. SDL builds its filter at run time in single precision (`GenerateResamplerFilter`), so there is no table in the source to copy. The tool is that function again in nushell, with every operation rounded to single precision: the Kaiser window's `BesselI0` series, `sqrtf`, the sinc table and the divisions. A double holds the exact result of one such operation closely enough that rounding it once more gives the single C gets. The tool reads the constants it can from the source (80 dB, 0.1102, 8.7) and refuses a source whose zero crossings or bits per crossing are not 6 and 3. It writes the 48 taps these rates meet: phases 0, 2, 4 and 6 of 8, twelve taps each, the constant term of each cubic. The sine is the one step that is not SDL's own arithmetic. SDL calls glibc's `sinf`, and the tool takes the double sine rounded to single. Only four sines reach these 48 taps, and one of them is of 0.

To check it against the real thing, the first gdb run also dumped SDL's `ResamplerFilter` from memory, 1536 bytes, transposed in groups of four as `SetupAudioResampler` leaves it for SSE. All 48 taps equal the tool's bit for bit, except that six of phase 0's zeros are -0.0 in SDL and 0.0 here. A zero tap's sign cannot reach a sample: its products are zeros, a zero added to a sum that is not zero changes nothing, and a sum of zeros of either sign converts to sample 0. The chunk comparison agrees. Bend has no negative float literal, so the file writes `F32.neg(x)`. `tests/sfx.bend` hashes the taps' bits on both lanes against the hash the tool prints, so a literal parsed differently on either lane fails the test.

The sources came from the flake's pinned nixpkgs: `nix-store -qR` on the dev shell's `chocolate-doom` gives `sdl3-3.4.14-lib`, `sdl2-compat-2.32.70` and `SDL2_mixer-2.8.2`; `nix-store -qd` on each gives its derivation, and `nix derivation show` gives its `src`. All three sources were already in the store. `nix build --no-link --print-out-paths --inputs-from . nixpkgs#sdl3.src` prints the same SDL3 path, and is what the tool's header names.

### The module, for ticket 04

    X.Sfx.read(a: Array<U32>, +lumps: List<&2, W.Wad.Lump>, +name: String) -> Array<U32> & Maybe<&2, X.Sfx.Sound>
    X.Sfx.run(s: X.Sfx.Sound) -> Maybe<&2, X.Sfx.Run>
    X.Sfx.pieces(r: X.Sfx.Run) -> Nat
    X.Sfx.out(r: X.Sfx.Run) -> List<&2, U32>
    X.Sfx.next(r: X.Sfx.Run) -> X.Sfx.Run

`read` gives none for a lump `CacheSFX` refuses, and for a missing one, whose size is 0. `run` gives none at a rate SDL is not given. A run is pure. `out` is its next piece, up to 1024 source samples' frames as 16-bit words, mono at 44100 Hz. `next` is the run past that piece, and `pieces` is how many are left. A writer loops `pieces` times, writing `out` and taking `next`, and holds one piece at a time. A piece recurses about 2000 deep, which is safe on the JS lane.

### The timing

A scratch program read every DS lump of Freedoom, expanded the 67 that take the SDL path and wrote them as hex to one file: 3322374 frames, 75.3 s of sound, from 1369096 bytes. The frame count equals the sum nushell gets from the lumps. Native, one thread: 1.69, 1.70 and 1.69 s, of which reading the 28 MB WAD is 0.22 s. With the default thread count it is 2.0 s. So expanding at load would cost about 1.5 s on this machine on top of the WAD read, for every sound. For E1M1's sounds alone it would be less. The longest single sound, DSCYBSIT at 207232 frames, takes about 0.2 s. The build-time node will take about 2 s a WAD.

### The test and the laws

`tests/sfx.bend` runs on both lanes: 0.5 s native, 3 s on bun. It prints the taps' hash, then DSNOWAY at 22050 Hz and DSITEMUP at 11025 Hz: rate and bytes as `tools/wad.nu` reads them, the hash of the whole expansion against Chocolate Doom's chunk from memory, the hash of the scaled frames against the recording, and frames by index read from the recording in nushell. The test's header has the commands. Then DSRLAUNC at 16000 Hz, which has no run, and four values of the float to 16-bit conversion worked by hand: two ties and the two clamps.

Two laws, both filled in: `sfx_refusals` pins `CacheSFX`'s checks at their edges, and `sfx_rates_unserved` says a sound at 16000 or 17990 Hz has no run whatever it holds. I tried a third for the rounding. The checker does not compute float operations, so those values went to the test.

### Surprises

- I expected the filter table to be the hard part. It came out bit for bit on the first run, because at these two rates only the constant term of 48 cubics is used, and the sines that reach them round the same way in glibc and in nushell.
- The order of the twelve additions is what would have been wrong if guessed: SDL's SSE path adds by lanes, not left to right.
- The door sounds clip. DSDOROPN and DSDORCLS both reach -32768 in Chocolate Doom's chunk.
- The README's license paragraph now names `src/sfx_taps.bend` and SDL's zlib license, since the tool follows SDL's function closely. The wording is open to maintainer review.
