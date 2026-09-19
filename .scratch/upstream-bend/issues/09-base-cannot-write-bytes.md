# 09: Base cannot write a byte, and reads bytes only as a list

**What is wrong:** Base can read a file's bytes but not write them. `File.read_bytes` answers the bytes, but `File.write` takes a `String` and encodes every character as UTF-8, so a byte from 128 to 255 goes to disk as two. There is no `File.write_bytes`. A demo, a video frame or a 16-bit sample cannot be written as it is. Base also reads bytes only as a list, one cell each, with no way to ask a file's size, so a program that wants a file in one flat array pays for 28 million list cells on the way.

**Where:** `File.read_bytes` and `File.write` in `bend2/base.bend`; `io_cstr` in `bend2/comp.ts` (line 5318) encodes the string. Bend commit e6676b0, checked 19 Sep 2026.

**Status:** ready-for-human (report upstream: ask for `File.write_bytes`, the mirror of `File.read_bytes`, and a read that answers an array)

## What we did about it

Until 19 Sep 2026 Bendoom carried two C effects of its own in `src/effs`: `Bytes.read`, a whole file as one flat array, and `Bytes.write`, bytes to a file. The maintainer wants no C in the repo and no patch to Bend, so both went.

- `Bytes.read` is Bend: it folds the file's 4096-byte chunks into an array that doubles whenever it is full, so one pass ends at the smallest power of two that holds the file. Freedoom's 28.8 MB WAD loads in about 320 ms inside the game, where the C effect took 72 ms; the window opens 0.3 s later, and the tests run about 3 s longer natively and 19 s longer on bun. perf puts the cost in Base's per-cell wrapping of `File.read_bytes`'s list.
- Bend writes bytes as hexadecimal text, which `File.write` and `IO.print` emit exactly, and coreutils' `basenc --base16 -d` turns the text back into bytes outside Bend: in the film's pipe into ffmpeg, in the music render's Nix build, and in the `bendoom` launcher, which turns a recorded demo into the vanilla `.lmp` when the game exits.

With `File.write_bytes` in Base, the hex step and the launcher's conversion go, and demos and frames are written as they are. A `File.read_bytes` that answered an array would make the reader one call.
