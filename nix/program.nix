# A root .bend program compiled to a binary: the program and src/ in,
# one executable out. film.bend and music.bend are built this way.
{ lib, llvmPackages_19, bend, pname, root }:

llvmPackages_19.stdenv.mkDerivation {
  inherit pname;
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [ (../. + "/${root}") ../src ];
  };

  nativeBuildInputs = [ bend ];

  buildPhase = ''
    runHook preBuild
    export HOME=$TMPDIR
    bend ${root} -o program
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 program $out/bin/program
    runHook postInstall
  '';

  meta.mainProgram = "program";
}
