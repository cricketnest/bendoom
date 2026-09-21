# 05: The mixer plays a sound over the song

**What to build:** One audio writer streams the song and playing effects with Chocolate Doom's sample arithmetic and clipping.

**Blocked by:** 04 (The sounds node)

**Status:** resolved

- [x] Effects stream front to back, holding only the frames about to be written
- [x] Scaling, channel order and saturation match SDL_mixer at the default volumes
- [x] With no effects, output equals the song and the existing stream expectations remain unchanged
- [x] Both lanes check varying window sizes, sound starts/ends and overlap
- [x] Three recorded comparisons have zero differing samples and zero largest difference
- [x] The superseded stream implementation is deleted

## Verification

The 21 Sep comparisons used Freedoom 0.13.0 and Chocolate Doom 3.1.1's SDL disk audio output, then emitted PCM from the real `Stream.window` and `Channel.hear` functions at the recorded effect starts. Each comparison covered every stereo sample in its window, including silence after effects ended.

| Recording | Setup | Frames compared | Differing samples | Largest difference |
| --- | --- | ---: | ---: | ---: |
| Centred DSNOWAY | `tools/listen.nu sounds -480 192 180 20,0,0,0,0 1,0,0,0,1 40,0,0,0,0` | 32768 | 0 | 0 |
| Door and pistol overlap | Isolated sector-80 door fixture, player 448,2048 facing 90; 20 idle, one use, one attack, 80 idle | 83968 | 0 | 0 |
| OPL music and DSNOWAY | Same centred scene; actual OPL callback output recorded alongside the final device output | 205824 | 0 | 0 |

The overlap capture starts DSDOROPN at frame 118784, volume 64/separation 129, and DSPISTOL at 125952, volume 64/separation 128. The music capture starts DSNOWAY at 110592. Its OPL samples were dumped immediately after `OPL3_GenerateStream` and fed to Bend as the song input: this checks the mixer against Chocolate Doom's actual music, independently of startup phase differences in a separately rendered song. It does not claim those two OPL startup phases are identical.

Artifacts are under `/tmp/m7-06/audio/`: `centred.json`, `overlap.json`, `music.json`, their Bend drivers and PCM outputs, and `music-trace/trace.gdb` plus the paired recordings. `tests/mixer.bend` retains the recorded grunt values and explicitly labels its separately rendered song hash as a regression pin.

## Implementation

`Stream.window` reads only the requested frames, folds effects in channel-slot order over silence, then adds the stereo song. Chocolate Doom registers its OPL callback with `MIX_CHANNEL_POST`; treating OPL as SDL_mixer's ordinary music hook gave the wrong clipping order. The saturation case in `tests/mixer.bend` distinguishes these orders: two effects of 30000 clip to 32767 before music of -30000 yields 2767.

`Stream.side` implements SDL_mixer's floating-point pan scaling truncated toward zero. `Stream.add` clips each integer sum to signed 16-bit range. Packed stereo words become floats only at `Audio.write`. A short effect read closes its file and frees its slot; a short song read limits the shared window so no effect samples are lost at a song boundary.
