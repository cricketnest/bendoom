{ lib, llvmPackages_19, bend, bun, alsa-lib, freedoom, music, sounds }:

llvmPackages_19.stdenv.mkDerivation {
  pname = "bendoom-tests";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      ../src
      (lib.fileset.difference ../tests ../tests/launchers.nu)
      ../film.bend
    ];
  };

  nativeBuildInputs = [ bend bun ];
  # tests/game.bend builds the game's loop, whose music links ALSA on
  # Linux.
  buildInputs = lib.optionals llvmPackages_19.stdenv.hostPlatform.isLinux [ alsa-lib ];

  BENDOOM_IWAD = "${freedoom}/share/games/doom/freedoom1.wad";
  BENDOOM_MUSIC = music;
  BENDOOM_SOUNDS = sounds;

  buildPhase = ''
    runHook preBuild
    export HOME=$TMPDIR
    ${lib.optionalString llvmPackages_19.stdenv.hostPlatform.isAarch64 ''
      ulimit -S -s 32768
      export BUN_JSC_maxPerThreadStackUsage=16777216
    ''}
    ${lib.readFile ./compile.sh}
    for t in tests/*.bend; do
      name=$(basename $t .bend)
      sed -n 's/^#|//p' $t > $name.want
      compile_bend $t $name ${if llvmPackages_19.stdenv.hostPlatform.isDarwin then "darwin" else "linux"}
      ./$name > $name.native.got
      diff $name.want $name.native.got
      echo "PASS $name native"
      bend $t -o $name.js
      bun $name.js > $name.js.got
      diff $name.want $name.js.got
      echo "PASS $name js"
    done
    runHook postBuild
  '';

  installPhase = ''
    install -Dm644 -t $out *.got
  '';
}
