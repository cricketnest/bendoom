# E1M1's song from one IWAD, as music.bend renders it: first.raw holds
# the first pass and second.raw the second, raw 16-bit little-endian
# stereo at 44100 Hz. The render program builds once for every IWAD.
{ lib, callPackage, runCommand, bend, iwad }:

let
  render = callPackage ./program.nix {
    inherit bend;
    pname = "bendoom-music-render";
    root = "music.bend";
  };
in
runCommand "bendoom-music" { } ''
  mkdir $out
  cd $out
  BENDOOM_IWAD=${lib.escapeShellArg iwad} ${lib.getExe render} --threads 1
''
