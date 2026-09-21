{ lib, runCommand, nushell, bash, dash, shellcheck }:

runCommand "bendoom-launcher-tests" {
  nativeBuildInputs = [ nushell bash dash shellcheck ];
  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      ../nix/launch.sh
      ../nix/portable.sh
      ../nix/compile.sh
      ../tools/play.sh
      ../tests/launchers.nu
    ];
  };
} ''
  cp -r "$src" source
  chmod -R u+w source
  cd source
  cat nix/portable.sh nix/launch.sh > portable.sh
  shellcheck --shell sh portable.sh tools/play.sh
  shellcheck --shell bash nix/compile.sh
  nu --no-config-file tests/launchers.nu
  touch "$out"
''
