# Every tests/*.bend, run against Freedoom on both lanes, native and
# JS; its output must equal its trailing #| lines on each.
{ lib, llvmPackages_19, bend, bun, freedoom }:

llvmPackages_19.stdenv.mkDerivation {
  pname = "bendoom-tests";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [ ../src ../tests ];
  };

  nativeBuildInputs = [ bend bun ];

  BENDOOM_IWAD = "${freedoom}/share/games/doom/freedoom1.wad";

  buildPhase = ''
    runHook preBuild
    export HOME=$TMPDIR
    for t in tests/*.bend; do
      name=$(basename $t .bend)
      sed -n 's/^#|//p' $t > $name.want
      bend $t -o $name
      ./$name > $name.native.got
      diff $name.want $name.native.got && echo "PASS $name native"
      bend $t -o $name.js
      bun $name.js > $name.js.got
      diff $name.want $name.js.got && echo "PASS $name js"
    done
    runHook postBuild
  '';

  installPhase = ''
    install -Dm644 -t $out *.got
  '';
}
