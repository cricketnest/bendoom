# bend PROOF.bend fails while any law is open or false.
{ lib, stdenvNoCC, bend }:

stdenvNoCC.mkDerivation {
  pname = "bendoom-proof";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      ../doom.bend
      ../src
      ../LAWS.bend
      ../PROOF.bend
    ];
  };

  nativeBuildInputs = [ bend ];

  buildPhase = ''
    runHook preBuild
    export HOME=$TMPDIR
    bend PROOF.bend | tee proof.log
    grep -q "All terms check." proof.log
    runHook postBuild
  '';

  installPhase = ''
    install -Dm644 proof.log $out/proof.log
  '';
}
