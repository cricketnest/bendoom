# 09: Base reads bytes only as a list

**What is wrong:** `File.read_bytes` and `File.read_at` return a list, one cell per byte, so a program that wants a file in one flat array pays for 28 million list cells on the way.

**Where:** `File.read_bytes` and `File.read_at` in `bend2/base.bend`, Bend 2.0.22. The original report also covered missing binary writes and file sizes; Bend 2.0.13 added `File.write_bytes`, `File.size` and `File.read_at`.

**Status:** ready-for-human (report upstream: ask for a byte read that answers an array)

## What we did about it

Until 19 Sep 2026 Bendoom carried two C effects of its own in `src/effs`: `Bytes.read`, a whole file as one flat array, and `Bytes.write`, bytes to a file. The maintainer wants no C in the repo and no patch to Bend, so both went.

- `Bytes.read` is Bend: it folds the file's 4096-byte chunks into an array that doubles whenever it is full, so one pass ends at the smallest power of two that holds the file. Freedoom's 28.8 MB WAD loads in about 320 ms inside the game, where the C effect took 72 ms; the window opens 0.3 s later, and the tests run about 3 s longer natively and 19 s longer on bun. perf puts the cost in Base's per-cell wrapping of `File.read_bytes`'s list.
- Bend writes bytes as hexadecimal text, which `File.write` and `IO.print` emit exactly, and coreutils' `basenc --base16 -d` turns the text back into bytes outside Bend: in the film's pipe into ffmpeg, in the music render's Nix build, and in the `bendoom` launcher, which turns a recorded demo into the vanilla `.lmp` when the game exits.

Adopting `File.write_bytes` would remove the hex step for demos and audio renders. `File.size` would remove the reader's array growth. Those are Bendoom cleanup tasks now; an array-returning read is the remaining upstream request.
