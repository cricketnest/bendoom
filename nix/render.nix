# A Bend program run once over one IWAD while the flake builds, whose
# output becomes raw files in the store: music.bend renders the song and
# sounds.bend expands the sounds. Bend writes bytes as hex text, so the
# program leaves <name>.hex in the build directory and basenc makes
# $out/<name>.raw of each. The program builds once for every IWAD, from
# the sources it imports alone, so a change to the game's other sources
# renders nothing again.
{ lib, callPackage, runCommand, bend, pname, root, sources, iwad }:

let
  program = callPackage ./program.nix {
    inherit bend root sources;
    pname = "${pname}-program";
  };
in
runCommand pname { } ''
  BENDOOM_IWAD=${lib.escapeShellArg iwad} ${lib.getExe program} --threads 1
  mkdir $out
  for hex in *.hex; do
    basenc --base16 -d "$hex" > "$out/''${hex%.hex}.raw"
  done
''
