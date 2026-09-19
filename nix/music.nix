# E1M1's song from one IWAD, as music.bend renders it: first.raw holds
# the first pass and second.raw the second, raw 16-bit little-endian
# stereo at 44100 Hz, decoded from the hex text the render writes in the
# build directory. The render program builds once for every IWAD,
# from the sources it imports alone, so a change to the game's other
# sources renders no song again.
{ lib, callPackage, runCommand, bend, iwad }:

let
  render = callPackage ./program.nix {
    inherit bend;
    pname = "bendoom-music-render";
    root = ../music.bend;
    sources = [
      ../src/bytes.bend ../src/fixed.bend ../src/midi.bend ../src/opl.bend
      ../src/opl_tables.bend ../src/player.bend ../src/song.bend ../src/vec.bend ../src/wad.bend
    ];
  };
in
runCommand "bendoom-music" { } ''
  BENDOOM_IWAD=${lib.escapeShellArg iwad} ${lib.getExe render} --threads 1
  mkdir $out
  basenc --base16 -d first.hex > $out/first.raw
  basenc --base16 -d second.hex > $out/second.raw
''
