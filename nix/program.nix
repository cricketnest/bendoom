# A root .bend program compiled to a binary: the program and the sources
# it imports in, one executable out, built with the stdenv's clang, which
# finds the libraries the program links through buildInputs.
{ lib, llvmPackages_19, bend, pname, root, sources, buildInputs ? [ ] }:

llvmPackages_19.stdenv.mkDerivation {
  inherit pname;
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions ([ root ] ++ sources);
  };

  nativeBuildInputs = [ bend ];
  inherit buildInputs;

  buildPhase = ''
    runHook preBuild
    export HOME=$TMPDIR
    bend ${baseNameOf root} -o program
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 program $out/bin/program
    runHook postInstall
  '';

  meta.mainProgram = "program";
}
