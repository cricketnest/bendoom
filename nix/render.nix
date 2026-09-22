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
