# bendoom-film: a demo in, an MP4 out. film.bend plays the demo and
# ffmpeg encodes its frames. Each of Doom's 320 by 200 pixels becomes a
# block 5 wide and 6 high, so the video is 1600 by 1200: the 4:3 of the
# monitor the frames were drawn for, every pixel the same size. H.264 in
# 4:2:0 plays everywhere; its colour, at half resolution, blurs the
# seams of blocks an odd width apart. Under it runs the IWAD's song, the
# first pass then the second forever, from frame zero as the game starts
# it on its first frame; the video arrives on a pipe, so its length is
# unknown until it ends and -shortest is what cuts the audio.
{ lib, callPackage, writers, bend, ffmpeg-headless, iwad, music }:

let
  frames = callPackage ./program.nix {
    inherit bend;
    pname = "bendoom-film-frames";
    root = "film.bend";
  };
  song = music iwad;
in
writers.writeNuBin "bendoom-film" ''
  # Encodes a demo Bendoom recorded as an MP4, 35 frames a second.
  def main [demo: path, video: path] {
    with-env {DEMO: $demo, BENDOOM_IWAD: ($env.BENDOOM_IWAD? | default "${iwad}")} {
      ^${lib.getExe frames} --threads 1
    } | (^${lib.getExe ffmpeg-headless} -loglevel error -stats -n
      -f rawvideo -pix_fmt rgb24 -s 320x200 -framerate 35 -i -
      -f s16le -ar 44100 -ac 2 -i ${song}/first.raw
      -stream_loop -1 -f s16le -ar 44100 -ac 2 -i ${song}/second.raw
      -filter_complex "[0:v]scale=1600:1200:flags=neighbor[v];[1:a][2:a]concat=n=2:v=0:a=1[a]"
      -map "[v]" -map "[a]" -c:v libx264 -crf 18 -pix_fmt yuv420p -c:a aac -shortest
      -movflags +faststart $video)
  }
''
