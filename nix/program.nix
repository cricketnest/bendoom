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
    ${lib.readFile ./compile.sh}
    compile_bend ${baseNameOf root} program ${if llvmPackages_19.stdenv.hostPlatform.isDarwin then "darwin" else "linux"}
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 program $out/bin/program
    runHook postInstall
  '';

  meta.mainProgram = "program";
}
