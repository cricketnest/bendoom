# Every tests/*.bend, built native and run against Freedoom; its output
# must equal its trailing #| lines.
{ lib, llvmPackages_19, bend, freedoom }:

llvmPackages_19.stdenv.mkDerivation {
  pname = "bendoom-tests";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [ ../src ../tests ];
  };

  nativeBuildInputs = [ bend ];

  BENDOOM_IWAD = "${freedoom}/share/games/doom/freedoom1.wad";

  buildPhase = ''
    runHook preBuild
    export HOME=$TMPDIR
    for t in tests/*.bend; do
      name=$(basename $t .bend)
      bend $t -o $name
      sed -n 's/^#|//p' $t > $name.want
      ./$name > $name.got
      diff $name.want $name.got && echo "PASS $name"
    done
    runHook postBuild
  '';

  installPhase = ''
    install -Dm644 -t $out *.got
  '';
}
