# bendoom-film: a demo in, an MP4 out. film.bend plays the demo, prints
# its frames as hex and writes its mixed audio as hex to a pipe; basenc
# makes both into bytes and ffmpeg encodes them.
# them. Each of Doom's 320 by 200 pixels becomes a block 5 wide and 6
# high, so the video is 1600 by 1200: the 4:3 of the monitor the frames
# were drawn for, every pixel the same size. H.264 in 4:2:0 plays
# everywhere; its colour, at half resolution, blurs the seams of blocks
# an odd width apart. The audio has exactly 1260 stereo frames per tic,
# with each tic's sounds mixed over its song before that tic's frame.
{ lib, callPackage, writers, bend, coreutils, ffmpeg-headless, iwad, music, sounds }:

let
  frames = callPackage ./program.nix {
    inherit bend;
    pname = "bendoom-film-frames";
    root = ../film.bend;
    sources = [ ../src ];
  };
  song = music iwad;
  effects = sounds iwad;
in
writers.writeNuBin "bendoom-film" ''
  # Encodes a demo Bendoom recorded as an MP4, 35 frames a second.
  def main [demo: path, video: path] {
    let scratch = mktemp --directory
    let hex = $scratch | path join audio.hex
    let raw = $scratch | path join audio.raw
    ^${coreutils}/bin/mkfifo $hex $raw
    let decoder = job spawn { ^${coreutils}/bin/basenc --base16 -d $hex o> $raw }
    try {
      with-env {
        DEMO: $demo
        AUDIO: $hex
        BENDOOM_IWAD: ($env.BENDOOM_IWAD? | default "${iwad}")
        BENDOOM_MUSIC: "${song}"
        BENDOOM_SOUNDS: "${effects}"
      } { ^${lib.getExe frames} --threads 1 }
      | ^${coreutils}/bin/basenc --base16 -d
      | (^${lib.getExe ffmpeg-headless} -loglevel error -stats -n
        -f rawvideo -pix_fmt rgb24 -s 320x200 -framerate 35 -i -
        -f s16le -ar 44100 -ac 2 -i $raw
        -filter_complex "[0:v]scale=1600:1200:flags=neighbor[v]"
        -map "[v]" -map 1:a -c:v libx264 -crf 18 -pix_fmt yuv420p -c:a aac -shortest
        -movflags +faststart $video)
    } finally {
      job kill $decoder
      rm --recursive $scratch
    }
  }
''
