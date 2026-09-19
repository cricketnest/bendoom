# 07: The film carries the music

**What to build:** `film` muxes its IWAD's render under the video: the first pass, then the second repeated, cut at the video's length, starting at frame zero, as the game starts the song on its first frame.

**Blocked by:** 05 (The repeat and the render node), and the demo recording work on main

**Status:** done

- [x] `film` and `film-shareware` take the music of their own IWAD
- [x] The audio starts at the first frame and ends with the last, checked with ffprobe on a filmed demo
- [x] A demo longer than one pass shows the repeat in the audio with no gap
- [x] The README's recording section says the video has the music

## Comments

19 Sep 2026, on an x86_64 benchmark host on AC power, balanced profile. Freedoom 0.13.0 unless the shareware WAD is named.

What landed. `nix/film.nix` takes `music`, the IWAD-to-render function from `flake.nix`, and applies it to its own `iwad`, so `film.override { iwad = shareware; }` carries the shareware song. ffmpeg gets two more inputs beside the piped video: `first.raw`, and `second.raw` with `-stream_loop -1`. A `concat` filter joins them into one endless stream and `-shortest` cuts it at the video's end. Nothing is written to a temporary file and the video's length is never needed up front. The audio is AAC at ffmpeg's default for stereo.

The shared shape. `nix/film.nix`'s `frames` and `nix/music.nix`'s `render` were the same derivation twice: a root `.bend` file and `src/` in, one binary out. Both are now `nix/program.nix`, which takes `pname` and `root` and installs `$out/bin/program` with `meta.mainProgram`, so callers use `lib.getExe`. `nix/bendoom.nix` is left alone: ticket 06 is editing it, and it differs anyway (X11 and ALSA in `buildInputs`, `LAWS.bend` and `PROOF.bend` in the fileset, a `makeWrapper` install and a `meta`), so folding it in would be a rewrite of the file rather than a reuse.

The demos. `RECORD` needs a window, so both demos were written by hand in the vanilla .lmp format, as `tools/oracle.nu` does: the 13-byte version 109 header `src/demo.bend` writes, four zero bytes a tic, then `0x80`. Idle tics, since the film only has to be long enough.

    def demo [tics: int] { [0x[6d 00 01 01 00 00 00 01 00 01 00 00 00]] | append (0..<$tics | each { 0x[00 00 00 00] }) | append 0x[80] | bytes collect }

The short film: 60 tics, 1.714286 s of video, filmed in 1.9 s. ffprobe gives the audio `start_time` 0.000000 and a duration of 1.695057 s. The long film: 4700 tics (134.3 s, past Freedoom's first pass of 130.61 s), filmed in 61 s at 77 frames a second. ffprobe gives video `start_time` 0.000000, duration 134.285714 s, 4700 frames; audio `start_time` 0.000000, duration 134.280998 s, 5784 AAC frames. The audio ends 4.7 ms before the video, which is less than one AAC frame of 1024 samples (23.2 ms): the cut lands on the last frame that fits.

The repeat has no gap. `ffmpeg -i long.mp4 -vn -f s16le -ar 44100 -ac 2 decoded.raw` gives 5,921,792 frames, the video's length. Freedoom's `first.raw` is 5,759,883 frames, so the seam is at 130.6096 s. Over the 1024 frames across it, the decode slid against the render (`first.raw`'s tail followed by `second.raw`'s head) has its lowest mean absolute difference at offset zero, 41.83, against 84.87 one frame early and 82.44 one frame late. The levels agree: mean absolute 719.88 in the render against 717.04 in the decode, peak 2497 against 2491. Frame by frame, the render's last frames of the first pass (291, 311), (268, 286), (249, 264), (233, 247) run into the second pass's first (216, 229), (204, 215), (196, 204), and the decode follows: (335, 329), (280, 318), (239, 287), (250, 281), (211, 289), (236, 227), (212, 252). The longest run of zero samples anywhere in the seam window is 0, so there is no silence either.

The same sweep over 512 frames at 5 s into the song, where it is loud, is a clean bowl with its bottom at offset zero: 283.18, against 316.93 and 321.84 a frame either way and 1069.16 and 1043.06 at 64 frames. So the audio is sample-aligned to the render from frame zero, not only at the seam. AAC is lossy, so the differences never reach zero; what the bowl shows is the alignment.

Two surprises. The first sweep put its minimum at the edge of the range because the window it compared against started at the sample under test instead of a padding before it, so every offset was shifted by the padding. The second is that a window at the song's very start carries no alignment information at all: the first frames are near silence, the differences there are the decoder's own noise, and the curve is flat. The seam and the loud passage are the windows worth measuring.

The shareware film. `nix build .#film-shareware` builds its own render: 4,234,424 frames a pass, 96.02 s, a different store path from Freedoom's 5,759,883. The wrapper names that path and no other.

`nix flake check` passes. The check builds neither render: `packages` are only evaluated, so the unfree WAD's song is still built by hand alone.

Commands:

    nix build .#film; nix build .#film-shareware
    ./result/bin/bendoom-film short.lmp short.mp4      (and long.lmp long.mp4)
    ffprobe -v error -show_streams -show_format long.mp4
    ffmpeg -v error -y -i long.mp4 -vn -f s16le -ar 44100 -ac 2 decoded.raw
    nix flake check

For ticket 08: the film's audio comes from `music iwad` and nothing else, so a change to the render's file names or sample format touches `nix/film.nix` and `nix/music.nix` together. `nix/program.nix` is where a root Bend program is built now.
