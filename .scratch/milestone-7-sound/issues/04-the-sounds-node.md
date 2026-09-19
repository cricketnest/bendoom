# 04: The sounds node

**What to build:** The flake builds every sound of a WAD once. A Bend program beside the music render writes one raw file for each sound in the sound table: signed 16-bit mono at 44100 Hz. A build node beside the music's runs it per WAD, and the launcher, the dev shell and the tests find the directory as they find the music.

**Blocked by:** 01 (The sim reports its sounds), 03 (One sound expands as Chocolate Doom's)

**Status:** resolved

- [x] One node per WAD expands the sounds the sound table names, each file named by its lump, with no binary download; a table sound at a rate the expansion does not serve fails the build
- [x] The packages that take an IWAD derive their sounds from it, so an override of the IWAD carries its sounds along, as it carries the music
- [x] The launcher defaults the sounds directory beside the IWAD and the music; the dev shell and the tests derivation get Freedoom's
- [x] The flake check builds Freedoom's sounds alone and never needs the unfree WAD
- [x] The ticket records the node's build time and its output size for both WADs
- [x] The music-from-the-wad ticket is updated to say it now covers sounds too

## Comments

19 and 20 Sep 2026, on an x86_64 benchmark host on AC power, balanced profile, with sibling worktrees building beside it.

### What landed

`sounds.bend` is the writer. It reads the WAD named by `BENDOOM_IWAD`, walks the table in `src/sound.bend`, and for each row writes `<LUMP>.hex` in the current directory: the lump read by `Sfx.read` and expanded by `Sfx.run`, a piece at a time through `Sfx.pieces`, `Sfx.out` and `Sfx.next`, each piece's samples turned to bytes low byte first and written with `Bytes.put_hex`. One row's file is written before the next row is read, and a piece is at most 1024 source samples, so the program holds the WAD and one piece and nothing else. The table is the only list of sounds, so a row added by milestone 6 is expanded with no change here.

The node is `nix/render.nix`, which is `nix/music.nix` made general and renamed: a Bend program built once by `nix/program.nix` from the sources it imports, run once with one IWAD, and every `<name>.hex` it leaves decoded to `$out/<name>.raw`. The music node's two fixed `basenc` lines became that loop, which gives the same `first.raw` and `second.raw` for the same `music.bend`, so the two nodes are one file and not two that differ in a name. `nix/music.nix` is deleted. In `flake.nix`, `render` takes the program's `pname`, `root` and `sources` and gives back the IWAD-to-directory function; `music` and `sounds` are its two applications, and `packages.sounds` and `packages.sounds-freedoom` sit beside `music` and `music-freedoom`, the unsuffixed one the shareware WAD's.

`nix/bendoom.nix` takes `sounds` as it takes `music` and applies it to its own IWAD, so the launcher defaults `BENDOOM_SOUNDS` beside `BENDOOM_IWAD` and `BENDOOM_MUSIC` and an override of the IWAD carries the sounds along. The dev shell sets `BENDOOM_SOUNDS` to Freedoom's, and `nix/tests.nix` takes `sounds` and sets it for every test.

`nix/film.nix` is untouched: the film mixes no sound until ticket 08, and an argument it does not read would be dead. That ticket's box already says both film packages build with their own WAD's sounds.

### For ticket 05

The mixer finds a sound's file at `$BENDOOM_SOUNDS/<lump>.raw`, where the lump is `Sound.lump(Sound.table(), sfx)` for the sfx number the event carries. The file is raw signed 16-bit little-endian mono at 44100 Hz with no header, so frame i is bytes 2i and 2i+1 and the sound ends where the file does, which a short read reports, exactly as `Stream.pull` finds a pass's end. `B.Bytes.le16` and `Stream.sample` already turn those bytes into samples. Both sides of Chocolate Doom's chunk hold the same sample (ticket 03), so the mixer scales the one sample by the channel's left and right volumes.

### The lumps, the sizes and the times

All thirteen rows of the table are in both WADs, read by `tools/wad.nu`'s `sound-lumps`, all playable and all at a rate SDL's converter is given: in Freedoom eight at 22050 Hz and five at 11025, in the shareware WAD all thirteen at 11025. The expansion makes 2 or 4 frames a source sample, so the node's output is the lump's sample count times that times two bytes:

| | Freedoom | shareware |
| --- | --- | --- |
| files | 13 | 13 |
| frames | 446,310 | 334,576 |
| bytes | 892,620 | 669,152 |
| largest file | DSDORCLS, 146,476 | DSDORCLS, 110,800 |

The byte counts are `du -sb` on the store paths, and both equal the sum computed from the lumps in nushell before the node ran.

Times, after the program is built: `nix build .#sounds-freedoom --rebuild` twice took 0.93 and 0.94 s, `nix build .#sounds --rebuild` 0.37 and 0.34 s, of which about 0.16 s is nix evaluating the flake (`nix build .#sounds-freedoom` with nothing to do). The program itself compiles in 4.2 s and is shared by both WADs, so a cold `nix build .#sounds-freedoom` is about 5 s. Run by hand outside nix, Freedoom's thirteen sounds take 0.75 s on one thread, of which ticket 03 measured 0.22 s reading the 28 MB WAD. Both `--rebuild` runs compared equal, so the node is reproducible.

### The failures

A table row the WAD has not got, one `CacheSFX` refuses, or one at a rate SDL's converter is not given exits 1 with the lump's name and writes no file for it, which fails the node. Checked in a scratch copy of the tree with a row added to the table: `DSRLAUNC` (16000 Hz in Freedoom) printed "D_E1M1: DSRLAUNC is at a rate the expansion does not serve", and `DSNOPE` printed "D_E1M1: DSNOPE is not in the WAD, or is a lump CacheSFX refuses", both exit 1. A `runCommand` whose script exits 1 fails the build, checked on its own with a one-line derivation.

### The test

`tests/sounds.bend` reads two of the node's own Freedoom files through `BENDOOM_SOUNDS` and prints each one's length in bytes and an FNV-1a hash of its 16-bit samples. The expected hashes are ticket 03's `chunk` values, which that ticket took from Chocolate Doom's own `Mix_Chunk` dumped from memory under gdb: DSNOWAY 973226569 and DSITEMUP 4006389721, the same two `tests/sfx.bend` prints from the WAD. So the test says the files in the store are the expansion that was checked against Chocolate Doom, not just the expansion this code makes today. The lengths, 33992 and 17384 bytes, are the lumps' 8498 and 2173 samples times 2 and 4 frames and two bytes a frame, worked from `tools/wad.nu`'s reading. Before writing the test I hashed both files in nushell and got the same two values.

The test folds the file through `Bytes.fold`, so it holds one 4096-byte chunk at a time and never the file. Native and bun both take under 0.05 s.

### Surprises

- Reading a whole file back is harder than reading a lump: `Bytes.read` pads to a power of two and cannot say how long the file was, so the test counts and hashes in the fold instead of indexing an array.
- The loop over the table could not be a helper that reads a row and calls back, since that is mutual recursion. It is a self-call in a `do` block whose shrinking argument is the list's tail, with the read's pair handed to a helper that returns the array through `IO`.
- Threading the WAD array through `IO` works, and an `IO.die` branch may drop it.

### Commands

    nix develop -c bend sounds.bend -o /tmp/m7-04/sounds
    BENDOOM_IWAD=<freedoom> /tmp/m7-04/sounds --threads 1
    nix build .#sounds .#sounds-freedoom .#bendoom .#bendoom-freedoom
    nix build .#sounds-freedoom --rebuild
    nix develop -c bend tests/sounds.bend -o t; BENDOOM_SOUNDS=<dir> ./t --threads 1
    nix flake check
