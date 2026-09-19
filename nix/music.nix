# E1M1's song from one IWAD, as music.bend renders it: first.raw holds
# the first pass and second.raw the second, raw 16-bit little-endian
# stereo at 44100 Hz. The render program builds once for every IWAD.
{ lib, llvmPackages_19, runCommand, bend, iwad }:

let
  render = llvmPackages_19.stdenv.mkDerivation {
    pname = "bendoom-music-render";
    version = "0.1.0";

    src = lib.fileset.toSource {
      root = ../.;
      fileset = lib.fileset.unions [ ../music.bend ../src ];
    };

    nativeBuildInputs = [ bend ];

    buildPhase = ''
      runHook preBuild
      export HOME=$TMPDIR
      bend music.bend -o music
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 music $out/bin/music
      runHook postInstall
    '';
  };
in
runCommand "bendoom-music" { } ''
  mkdir $out
  cd $out
  BENDOOM_IWAD=${lib.escapeShellArg iwad} ${render}/bin/music --threads 1
''
