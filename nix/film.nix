# bendoom-film: a demo in, an MP4 out. film.bend plays the demo and
# ffmpeg encodes its frames. Each of Doom's 320 by 200 pixels becomes a
# block 5 wide and 6 high, so the video is 1600 by 1200: the 4:3 of the
# monitor the frames were drawn for, every pixel the same size. H.264 in
# 4:2:0 plays everywhere; its colour, at half resolution, blurs the
# seams of blocks an odd width apart.
{ lib, llvmPackages_19, writers, bend, ffmpeg-headless, iwad }:

let
  frames = llvmPackages_19.stdenv.mkDerivation {
    pname = "bendoom-film-frames";
    version = "0.1.0";

    src = lib.fileset.toSource {
      root = ../.;
      fileset = lib.fileset.unions [ ../film.bend ../src ];
    };

    nativeBuildInputs = [ bend ];

    buildPhase = ''
      runHook preBuild
      export HOME=$TMPDIR
      bend film.bend -o film
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 film $out/bin/film
      runHook postInstall
    '';
  };
in
writers.writeNuBin "bendoom-film" ''
  # Encodes a demo Bendoom recorded as an MP4, 35 frames a second.
  def main [demo: path, video: path] {
    with-env {DEMO: $demo, BENDOOM_IWAD: ($env.BENDOOM_IWAD? | default "${iwad}")} {
      ^${frames}/bin/film --threads 1
    } | (^${lib.getExe ffmpeg-headless} -loglevel error -stats -n -f rawvideo -pix_fmt rgb24 -s 320x200
      -framerate 35 -i - -vf scale=1600:1200:flags=neighbor -c:v libx264 -crf 18 -pix_fmt yuv420p
      -movflags +faststart $video)
  }
''
